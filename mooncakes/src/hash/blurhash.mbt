///|
/// BlurHash encoder
///
/// Reference algorithm: https://blurha.sh
///
/// Encode an RGBA image into a BlurHash string.
/// - `width`, `height`: image size in pixels
/// - `rgba`: length = 4 * width * height, layout = RGBA, channels in 0..255
/// - `num_comp_x` / `num_comp_y`: number of frequency components in X / Y directions, clamped to [1, 9]
pub fn rgba_to_blur_hash(
  width : Int,
  height : Int,
  rgba : Array[Byte],
  num_comp_x : Int,
  num_comp_y : Int,
) -> String {
  if width <= 0 || height <= 0 {
    return ""
  }
  if rgba.length() != width * height * 4 {
    return ""
  }

  // Clamp components to [1, 9] as in the reference implementation
  let nx = @cmp.maximum(1, @cmp.minimum(9, num_comp_x))
  let ny = @cmp.maximum(1, @cmp.minimum(9, num_comp_y))

  // Precompute linear RGB (un-premultiplied alpha) for each pixel
  let n = width * height
  let linear_r : Array[Double] = Array::make(n, 0.0)
  let linear_g : Array[Double] = Array::make(n, 0.0)
  let linear_b : Array[Double] = Array::make(n, 0.0)
  for y in 0..<height {
    for x in 0..<width {
      let idx = (x + y * width) * 4
      let r_srgb = rgba[idx].to_double() / 255.0
      let g_srgb = rgba[idx + 1].to_double() / 255.0
      let b_srgb = rgba[idx + 2].to_double() / 255.0
      let a = rgba[idx + 3].to_double() / 255.0
      let (lr, lg, lb) = if a < 0.5 {
        (0.0, 0.0, 0.0)
      } else {
        let ar = srgb_to_linear(r_srgb)
        let ag = srgb_to_linear(g_srgb)
        let ab = srgb_to_linear(b_srgb)
        let inv_a = 1.0 / a
        (ar * inv_a, ag * inv_a, ab * inv_a)
      }
      let p = x + y * width
      linear_r[p] = lr
      linear_g[p] = lg
      linear_b[p] = lb
    }
  }

  // Compute DCT-like basis coefficients
  let factors : Array[(Double, Double, Double)] = Array::new()
  let w_d = width.to_double()
  let h_d = height.to_double()
  let norm_base = 1.0 / (w_d * h_d)
  for j in 0..<ny {
    for i in 0..<nx {
      let normalisation = if i == 0 && j == 0 { 1.0 } else { 2.0 }
      let mut r_acc = 0.0
      let mut g_acc = 0.0
      let mut b_acc = 0.0
      for y in 0..<height {
        let fy = @math.cos(@math.PI * j.to_double() * y.to_double() / h_d)
        for x in 0..<width {
          let fx = @math.cos(@math.PI * i.to_double() * x.to_double() / w_d)
          let basis = fx * fy
          let p = x + y * width
          r_acc = r_acc + basis * linear_r[p]
          g_acc = g_acc + basis * linear_g[p]
          b_acc = b_acc + basis * linear_b[p]
        }
      }
      let scale = normalisation * norm_base
      factors.push((r_acc * scale, g_acc * scale, b_acc * scale))
    }
  }
  let dc = factors[0]
  let dc_value = encode_dc(dc.0, dc.1, dc.2)
  let mut ac_max = 0.0
  if nx * ny > 1 {
    for idx in 1..<(nx * ny) {
      let f = factors[idx]
      let r_abs = f.0.abs()
      let g_abs = f.1.abs()
      let b_abs = f.2.abs()
      let local_max = @cmp.maximum(r_abs, @cmp.maximum(g_abs, b_abs))
      ac_max = @cmp.maximum(ac_max, local_max)
    }
  }
  let mut quant_max_ac = 0
  if nx * ny > 1 {
    quant_max_ac = @cmp.maximum(
      0,
      @cmp.minimum(82, (ac_max * 166.0 - 0.5).to_int()),
    )
  }
  let ac_scale = (quant_max_ac + 1).to_double() / 166.0

  // Build output in base83
  let chars : Array[Char] = Array::new()
  let size_flag = nx - 1 + (ny - 1) * 9
  let size_chars = encode_base83_chars(size_flag, 1)
  for c in size_chars {
    chars.push(c)
  }
  let quant_max_chars = encode_base83_chars(quant_max_ac, 1)
  for c in quant_max_chars {
    chars.push(c)
  }
  let dc_chars = encode_base83_chars(dc_value, 4)
  for c in dc_chars {
    chars.push(c)
  }
  if nx * ny > 1 {
    for idx in 1..<(nx * ny) {
      let f = factors[idx]
      let ac_val = encode_ac(f.0, f.1, f.2, ac_scale)
      let ac_chars = encode_base83_chars(ac_val, 2)
      for c in ac_chars {
        chars.push(c)
      }
    }
  }
  String::from_array(chars)
}

///|
fn base83_alphabet() -> Array[Char] {
  [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
    'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
    'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '#', '$',
    '%', '*', '+', ',', '-', '.', ':', ';', '=', '?', '@', '[', ']', '^', '_', '{',
    '|', '}', '~',
  ]
}

///|
fn encode_base83_chars(value : Int, length : Int) -> Array[Char] {
  let alphabet = base83_alphabet()
  let chars : Array[Char] = Array::make(length, '0')
  let mut v = value
  for i in 0..<length {
    let digit = v % 83
    v = v / 83
    chars[length - 1 - i] = alphabet[digit]
  }
  chars
}

///|
fn srgb_to_linear(v : Double) -> Double {
  if v <= 0.04045 {
    v / 12.92
  } else {
    @math.pow((v + 0.055) / 1.055, 2.4)
  }
}

///|
fn linear_to_srgb(v : Double) -> Int {
  let clamped = if v <= 0.0 { 0.0 } else if v >= 1.0 { 1.0 } else { v }
  let srgb = if clamped <= 0.0031308 {
    clamped * 12.92
  } else {
    1.055 * @math.pow(clamped, 1.0 / 2.4) - 0.055
  }
  (srgb * 255.0 + 0.5).to_int()
}

///|
fn encode_dc(r : Double, g : Double, b : Double) -> Int {
  let r_int = linear_to_srgb(r)
  let g_int = linear_to_srgb(g)
  let b_int = linear_to_srgb(b)
  (r_int << 16) + (g_int << 8) + b_int
}

///|
/// Signed square root: sign(v) * sqrt(|v|)
/// Implemented via `@math.pow(abs_v, 0.5)` to avoid relying on a dedicated `sqrt`.
fn sign_sqrt(v : Double) -> Double {
  let abs_v = if v < 0.0 { -v } else { v }
  let root = @math.pow(abs_v, 0.5)
  if v < 0.0 {
    -root
  } else {
    root
  }
}

///|
fn encode_ac(r : Double, g : Double, b : Double, max_val : Double) -> Int {
  if max_val == 0.0 {
    return 0
  }
  let quant_r = @cmp.maximum(
    0,
    @cmp.minimum(18, (sign_sqrt(r / max_val) * 9.0 + 9.5).to_int()),
  )
  let quant_g = @cmp.maximum(
    0,
    @cmp.minimum(18, (sign_sqrt(g / max_val) * 9.0 + 9.5).to_int()),
  )
  let quant_b = @cmp.maximum(
    0,
    @cmp.minimum(18, (sign_sqrt(b / max_val) * 9.0 + 9.5).to_int()),
  )
  quant_r * 19 * 19 + quant_g * 19 + quant_b
}

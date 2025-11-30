///|
/// Converts an RGBA image to a ThumbHash byte array.
///
/// ThumbHash is a compact image fingerprint that captures the essential
/// color and structure information of an image, enabling quick comparison
/// and efficient transmission.
///
/// ### Parameters
/// - `w: Int` - The width of the image in pixels.
/// - `h: Int` - The height of the image in pixels.
/// - `rgba: Array[Byte]` - The image pixel data in RGBA format, with 4 bytes per pixel
///   (Red, Green, Blue, Alpha), each component ranging from 0 to 255.
///
/// ### Returns
/// A `Array[Byte]` representing the ThumbHash encoding of the input image.
///
/// # Description
/// 1. Computes the average color of the image, accounting for alpha transparency.
/// 2. Determines whether the image contains transparency (alpha channel).
/// 3. Converts the image data from RGBA to LPQA format:
///    - Luminance (L),
///    - Yellow-Blue difference (P),
///    - Red-Green difference (Q),
///    - Alpha (A).
/// 4. Applies Discrete Cosine Transform (DCT) on each channel to obtain DC and AC coefficients.
/// 5. Normalizes and quantizes these coefficients to build the ThumbHash byte sequence.
///
/// ### Notes
/// - The function adapts luminance sampling resolution depending on presence of alpha channel.
/// - The resulting ThumbHash is useful for fast image similarity checks.
///
/// ### References
/// ThumbHash algorithm inspired by https://github.com/evanw/thumbhash
///
pub fn rgba_to_thumb_hash(w : Int, h : Int, rgba : Array[Byte]) -> Array[Byte] {
  // Determine the average color
  let mut avg_r = 0.0
  let mut avg_g = 0.0
  let mut avg_b = 0.0
  let mut avg_a = 0.0
  for rc in rgba.chunks(4) {
    let alpha = rc[3].to_double() / 255.0
    avg_r = avg_r + alpha / 255.0 * rc[0].to_double()
    avg_g = avg_g + alpha / 255.0 * rc[1].to_double()
    avg_b = avg_b + alpha / 255.0 * rc[2].to_double()
    avg_a = avg_a + alpha
  }
  if avg_a > 0.0 {
    avg_r /= avg_a
    avg_g /= avg_a
    avg_b /= avg_a
  }
  let has_alpha = avg_a < (w * h).to_double()
  let l_limit = if has_alpha { 5 } else { 7 } // Use fewer luminance bits if there's alpha
  let lx = @cmp.maximum(
    (l_limit * w / @cmp.maximum(w, h)).to_double().round(),
    1,
  )
  let ly = @cmp.maximum(
    (l_limit * h / @cmp.maximum(w, h)).to_double().round(),
    1,
  )
  let l = Array::new() // luminance
  let p = Array::new() // yellow - blue
  let q = Array::new() // red - green
  let a = Array::new() // alpha

  // Convert the image from RGBA to LPQA (composite atop the average color)
  for rc in rgba.chunks(4) {
    let alpha = rc[3].to_double() / 255.0
    let r = avg_r * (1.0 - alpha) + alpha / 255.0 * rc[0].to_double()
    let g = avg_g * (1.0 - alpha) + alpha / 255.0 * rc[0].to_double()
    let b = avg_b * (1.0 - alpha) + alpha / 255.0 * rc[0].to_double()
    l.push((r + g + b) / 3.0)
    p.push((r + g) / 2.0 - b)
    q.push(r - g)
    a.push(alpha)
  }
  let encode_channel = fn(
    channel : Array[Double],
    nx : Int,
    ny : Int,
  ) -> (Double, Array[Double], Double) {
    let mut dc = 0.0
    let mut scale = 0.0
    let mut ac = Array::new()
    let fx = [0.0].repeat(w)
    for cy in 0..<ny {
      let mut cx = 0
      while cx * ny < nx * (ny - cy) {
        let mut f = 0.0
        for x in 0..<w {
          fx[x] = @math.cos(
            @math.PI / w.to_double() * cx.to_double() * (x.to_double() + 0.5),
          )
        }
        for y in 0..<h {
          let fy = @math.cos(
            @math.PI / h.to_double() * cy.to_double() * (y.to_double() + 0.5),
          )
          for x in 0..<w {
            f += channel[x + y * w] * fx[x] * fy
          }
        }
        f /= (w * h).to_double()
        if cx > 0 || cy > 0 {
          ac.push(f)
          scale = @cmp.maximum(f.abs(), scale)
        } else {
          dc = f
        }
        cx += 1
      }
    }
    if scale > 0.0 {
      ac = ac.map(a => 0.5 + 0.5 / scale * a)
    }
    (dc, ac, scale)
  }

  // Encode using the DCT into DC (constant) and normalized AC (varying) terms
  let (l_dc, l_ac, l_scale) = encode_channel(
    l,
    @cmp.maximum(lx.to_int(), 3),
    @cmp.maximum(ly.to_int(), 3),
  )
  let (p_dc, p_ac, p_scale) = encode_channel(p, 3, 3)
  let (q_dc, q_ac, q_scale) = encode_channel(q, 3, 3)
  let (a_dc, a_ac, a_scale) = if has_alpha {
    encode_channel(a, 5, 5)
  } else {
    (1.0, Array::new(), 1.0)
  }

  // Encode the first 24 bits (3 bytes) of the hash header:
  // These bits encode average luminance, chroma DC, scale, and alpha presence.
  let header24 = (63.0 * l_dc).round().to_int() + // 6 bits: average luminance [0, 63]
    ((31.5 + 31.5 * p_dc).round().to_int() << 6) + // 6 bits: red-green chroma DC [-1, 1] mapped to [0, 63]
    ((31.5 + 31.5 * q_dc).round().to_int() << 12) + // 6 bits: blue-yellow chroma DC [-1, 1] mapped to [0, 63]
    ((31.0 * l_scale).round().to_int() << 18) + // 5 bits: luminance AC scale [0, 1] mapped to [0, 31]
    ((if has_alpha { 1 } else { 0 }) << 23) // 1 bit : alpha presence flag (1 = has alpha)

  // Encode the next 16 bits (2 bytes) of the hash header:
  // These bits encode orientation and chroma AC scale.
  let header16 = (if w > h { ly } else { lx }).to_int() + // 3 bits: number of X or Y AC coefficients (orientation-dependent)
    ((63.0 * p_scale).round().to_int() << 3) + // 6 bits: red-green chroma AC scale [0, 1]s
    ((63.0 * q_scale).round().to_int() << 9) + // 6 bits: blue-yellow chroma AC scale [0, 1]
    ((if w > h { 1 } else { 0 }) << 15) // 1 bit : landscape orientation flag

  // Write the header to the hash byte array (little endian)
  let hash : Array[Byte] = Array::new()
  hash.append([
    (header24 & 0xFF).to_byte(),
    ((header24 >> 8) & 0xFF).to_byte(),
    ((header24 >> 16) & 0xFF).to_byte(),
    (header16 & 0xFF).to_byte(),
    ((header16 >> 8) & 0xFF).to_byte(),
  ])
  let mut is_odd = false
  if has_alpha {
    let a_dc_val = (15.0 * a_dc).round()
    let a_scale_val = (15.0 * a_scale).round()
    let byte = a_dc_val + a_scale_val * 16
    hash.push(byte.to_le_bytes().get(0).unwrap_or_default())
  }

  // Write the varying factors
  for ac in [l_ac, p_ac, q_ac] {
    for f in ac {
      let u = (15.0 * f).round()
      if is_odd {
        let last = hash.last().unwrap()
        let last_val = last +
          u.to_int().to_le_bytes().get(0).unwrap_or_default() * 16
        let _ = hash.pop()
        hash.push(last_val)
      } else {
        hash.push(u.to_int().to_le_bytes().get(0).unwrap_or_default())
      }
      is_odd = !is_odd
    }
  }
  if has_alpha {
    for f in a_ac {
      let u = (15.0 * f).round()
      if is_odd {
        let last = hash.last().unwrap()
        let last_val = last +
          u.to_int().to_le_bytes().get(0).unwrap_or_default() * 16
        let _ = hash.pop()
        hash.push(last_val)
      } else {
        hash.push(u.to_int().to_le_bytes().get(0).unwrap_or_default())
      }
      is_odd = !is_odd
    }
  }
  hash
}

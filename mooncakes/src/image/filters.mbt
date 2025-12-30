///|
/// Convolution and basic filters.

///|
/// Apply a 3x3 convolution kernel to RGB channels, keeping alpha from the center pixel.
///
/// `kernel` must be length 9 in row-major order:
/// `[k00, k01, k02, k10, k11, k12, k20, k21, k22]` where (x,y) is column,row.
pub fn Image::convolve3x3(
  self : Image,
  kernel : Array[Double],
  border : BorderMode,
) -> Image {
  self.convolve3x3_ex(kernel, 1.0, 0.0, border)
}

///|
/// Convolution with an extra scale factor and bias: `out = acc * factor + bias`.
pub fn Image::convolve3x3_ex(
  self : Image,
  kernel : Array[Double],
  factor : Double,
  bias : Double,
  border : BorderMode,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if kernel.length() != 9 {
    return Image::default()
  }
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut r = 0.0
      let mut g = 0.0
      let mut b = 0.0
      let mut ki = 0
      let offsets : Array[Int] = [-1, 0, 1]
      for oy in offsets {
        for ox in offsets {
          let p = self.sample(x + ox, y + oy, border)
          let k = kernel[ki]
          r = r + p.r.to_double() * k
          g = g + p.g.to_double() * k
          b = b + p.b.to_double() * k
          ki += 1
        }
      }
      let center = self.sample(x, y, border)
      RgbaColor::{
        r: clamp_u8_f(r * factor + bias),
        g: clamp_u8_f(g * factor + bias),
        b: clamp_u8_f(b * factor + bias),
        a: center.a,
      }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// 3x3 box blur (average of neighbors) on RGB, keeping alpha.
pub fn Image::box_blur3(self : Image, border : BorderMode) -> Image {
  let k : Array[Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
  self.convolve3x3_ex(k, 1.0 / 9.0, 0.0, border)
}

///|
/// 3x3 Gaussian blur kernel on RGB, keeping alpha.
pub fn Image::gaussian_blur3(self : Image, border : BorderMode) -> Image {
  let k : Array[Double] = [1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0]
  self.convolve3x3_ex(k, 1.0 / 16.0, 0.0, border)
}

///|
/// 3x3 sharpen filter on RGB, keeping alpha.
pub fn Image::sharpen3(self : Image, border : BorderMode) -> Image {
  let k : Array[Double] = [0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0]
  self.convolve3x3(k, border)
}

///|
/// Sobel edge magnitude (grayscale output), based on RGB average luminance.
pub fn Image::sobel_edges(self : Image, border : BorderMode) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let gx : Array[Double] = [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0]
  let gy : Array[Double] = [-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0]
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut sx = 0.0
      let mut sy = 0.0
      let mut ki = 0
      let offsets : Array[Int] = [-1, 0, 1]
      for oy in offsets {
        for ox in offsets {
          let p = self.sample(x + ox, y + oy, border)
          let lum = (p.r.to_double() + p.g.to_double() + p.b.to_double()) / 3.0
          sx = sx + lum * gx[ki]
          sy = sy + lum * gy[ki]
          ki += 1
        }
      }
      let mag = (sx * sx + sy * sy).sqrt()
      let v = clamp_u8_f(mag)
      let a = self.sample(x, y, border).a
      RgbaColor::{ r: v, g: v, b: v, a }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Apply a 5x5 convolution kernel to RGB channels, keeping alpha from the center pixel.
///
/// `kernel` must be length 25 in row-major order.
pub fn Image::convolve5x5(
  self : Image,
  kernel : Array[Double],
  border : BorderMode,
) -> Image {
  self.convolve5x5_ex(kernel, 1.0, 0.0, border)
}

///|
/// 5x5 convolution with an extra scale factor and bias: `out = acc * factor + bias`.
pub fn Image::convolve5x5_ex(
  self : Image,
  kernel : Array[Double],
  factor : Double,
  bias : Double,
  border : BorderMode,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if kernel.length() != 25 {
    return Image::default()
  }
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut r = 0.0
      let mut g = 0.0
      let mut b = 0.0
      let mut ki = 0
      // 5x5 offsets: -2..2
      for oy_i in 0..<5 {
        let oy = oy_i - 2
        for ox_i in 0..<5 {
          let ox = ox_i - 2
          let p = self.sample(x + ox, y + oy, border)
          let k = kernel[ki]
          r = r + p.r.to_double() * k
          g = g + p.g.to_double() * k
          b = b + p.b.to_double() * k
          ki += 1
        }
      }
      let center = self.pixels[idx]
      RgbaColor::{
        r: clamp_u8_f(r * factor + bias),
        g: clamp_u8_f(g * factor + bias),
        b: clamp_u8_f(b * factor + bias),
        a: center.a,
      }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

fn filters_reflect_coord(c0 : Int, max : Int) -> Int {
  if max <= 0 {
    return 0
  }
  let mut c = c0
  while c < 0 || c >= max {
    if c < 0 {
      c = -c - 1
    } else {
      c = 2 * max - c - 1
    }
  }
  c
}

///|
/// Separable convolution using 1D kernels.
///
/// Applies `kernel_x` horizontally then `kernel_y` vertically. Kernels must have odd length.
/// Alpha is taken from the center pixel.
pub fn Image::separable_convolve(
  self : Image,
  kernel_x : Array[Double],
  kernel_y : Array[Double],
  border : BorderMode,
) -> Image {
  self.separable_convolve_ex(kernel_x, kernel_y, 1.0, 0.0, border)
}

///|
/// Separable convolution with an extra scale factor and bias: `out = acc * factor + bias`.
pub fn Image::separable_convolve_ex(
  self : Image,
  kernel_x : Array[Double],
  kernel_y : Array[Double],
  factor : Double,
  bias : Double,
  border : BorderMode,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if kernel_x.is_empty() || kernel_y.is_empty() {
    return Image::default()
  }
  if kernel_x.length() % 2 == 0 || kernel_y.length() % 2 == 0 {
    return Image::default()
  }

  let rx = kernel_x.length() / 2
  let ry = kernel_y.length() / 2

  // Precompute sum(kernel_x) for constant/zero out-of-bounds rows.
  let sum_kx = kernel_x.fold(init=0.0, fn(acc : Double, v : Double) { acc + v })

  // Horizontal pass into temporary buffers.
  let n = w * h
  let tmp_r : Array[Double] = Array::make(n, 0.0)
  let tmp_g : Array[Double] = Array::make(n, 0.0)
  let tmp_b : Array[Double] = Array::make(n, 0.0)

  for y in 0..<h {
    for x in 0..<w {
      let mut rr = 0.0
      let mut gg = 0.0
      let mut bb = 0.0
      for i in 0..<kernel_x.length() {
        let ox = i - rx
        let p = self.sample(x + ox, y, border)
        let k = kernel_x[i]
        rr = rr + p.r.to_double() * k
        gg = gg + p.g.to_double() * k
        bb = bb + p.b.to_double() * k
      }
      let idx = x + y * w
      tmp_r[idx] = rr
      tmp_g[idx] = gg
      tmp_b[idx] = bb
    }
  }

  // Vertical pass reading tmp buffers; handle y out-of-bounds based on border.
  let out_pixels : Array[RgbaColor] = (0)
    .until(n)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut rr = 0.0
      let mut gg = 0.0
      let mut bb = 0.0

      for j in 0..<kernel_y.length() {
        let oy = j - ry
        let sy = y + oy
        let k = kernel_y[j]

        if sy >= 0 && sy < h {
          let sidx = x + sy * w
          rr = rr + tmp_r[sidx] * k
          gg = gg + tmp_g[sidx] * k
          bb = bb + tmp_b[sidx] * k
        } else {
          match border {
            BorderMode::Clamp => {
              let my = if sy < 0 { 0 } else { h - 1 }
              let sidx = x + my * w
              rr = rr + tmp_r[sidx] * k
              gg = gg + tmp_g[sidx] * k
              bb = bb + tmp_b[sidx] * k
            }
            BorderMode::Reflect => {
              let my = filters_reflect_coord(sy, h)
              let sidx = x + my * w
              rr = rr + tmp_r[sidx] * k
              gg = gg + tmp_g[sidx] * k
              bb = bb + tmp_b[sidx] * k
            }
            BorderMode::Constant(c) => {
              rr = rr + c.r.to_double() * sum_kx * k
              gg = gg + c.g.to_double() * sum_kx * k
              bb = bb + c.b.to_double() * sum_kx * k
            }
            BorderMode::Zero => ()
          }
        }
      }

      let center = self.pixels[idx]
      RgbaColor::{
        r: clamp_u8_f(rr * factor + bias),
        g: clamp_u8_f(gg * factor + bias),
        b: clamp_u8_f(bb * factor + bias),
        a: center.a,
      }
    })
    .collect()

  Image::{ pixels: out_pixels, width: w, heigth: h }
}

fn median_sort_inplace(values : Array[Int]) -> Unit {
  // Insertion sort for small windows.
  let n = values.length()
  for i in 1..<n {
    let key = values[i]
    let mut j = i - 1
    while j >= 0 && values[j] > key {
      values[j + 1] = values[j]
      j = j - 1
    }
    values[j + 1] = key
  }
}

///|
/// Median filter over RGB channels with a square window of radius `radius`.
///
/// `radius=1` => 3x3, `radius=2` => 5x5. Alpha is taken from the center pixel.
pub fn Image::median_filter(self : Image, radius : Int, border : BorderMode) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if radius < 0 {
    return Image::default()
  }
  if radius == 0 {
    return self
  }
  let size = 2 * radius + 1
  let win = size * size
  let n = w * h

  let out_pixels : Array[RgbaColor] = (0)
    .until(n)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let rs : Array[Int] = Array::make(win, 0)
      let gs : Array[Int] = Array::make(win, 0)
      let bs : Array[Int] = Array::make(win, 0)
      let mut k = 0
      for oy_i in 0..<size {
        let oy = oy_i - radius
        for ox_i in 0..<size {
          let ox = ox_i - radius
          let p = self.sample(x + ox, y + oy, border)
          rs[k] = p.r.to_int()
          gs[k] = p.g.to_int()
          bs[k] = p.b.to_int()
          k += 1
        }
      }
      median_sort_inplace(rs)
      median_sort_inplace(gs)
      median_sort_inplace(bs)
      let mid = win / 2
      let center = self.pixels[idx]
      RgbaColor::{
        r: rs[mid].to_byte(),
        g: gs[mid].to_byte(),
        b: bs[mid].to_byte(),
        a: center.a,
      }
    })
    .collect()

  Image::{ pixels: out_pixels, width: w, heigth: h }
}

fn filters_abs(v : Double) -> Double {
  if v < 0.0 { -v } else { v }
}

fn filters_exp(x : Double) -> Double {
  // exp(x) = 2^(x / ln(2))
  let ln2 = 0.6931471805599453
  @math.pow(2.0, x / ln2)
}

///|
/// Box blur with a square window of radius `radius`.
///
/// `radius=1` => 3x3. This is implemented via separable convolution.
pub fn Image::box_blur(self : Image, radius : Int, border : BorderMode) -> Image {
  if radius < 0 {
    return Image::default()
  }
  if radius == 0 {
    return self
  }
  let size = 2 * radius + 1
  let k : Array[Double] = Array::make(size, 1.0)
  self.separable_convolve_ex(k, k, 1.0 / (size * size).to_double(), 0.0, border)
}

///|
/// Gaussian blur with radius `radius` and standard deviation `sigma`.
///
/// Implemented via separable convolution using a 1D Gaussian kernel.
pub fn Image::gaussian_blur(
  self : Image,
  radius : Int,
  sigma : Double,
  border : BorderMode,
) -> Image {
  if radius < 0 {
    return Image::default()
  }
  if radius == 0 {
    return self
  }
  let s = if sigma <= 0.0 { 1.0 } else { sigma }
  let size = 2 * radius + 1
  let kernel : Array[Double] = (0)
    .until(size)
    .map(fn(i) {
      let x = (i - radius).to_double()
      // exp(-x^2 / (2*sigma^2))
      filters_exp(-(x * x) / (2.0 * s * s))
    })
    .collect()
  let sum = kernel.fold(init=0.0, fn(acc : Double, v : Double) { acc + v })
  if sum <= 0.0 {
    return Image::default()
  }
  self.separable_convolve_ex(kernel, kernel, 1.0 / (sum * sum), 0.0, border)
}

///|
/// Motion blur using a line kernel of `length` pixels at `angle` radians.
///
/// This is implemented as a generic NxN convolution where N is the next odd
/// number >= length.
pub fn Image::motion_blur(
  self : Image,
  length : Int,
  angle : Double,
  border : BorderMode,
) -> Image {
  if length <= 0 {
    return Image::default()
  }
  if length == 1 {
    return self
  }
  let size = if length % 2 == 0 { length + 1 } else { length }
  let r = size / 2
  let kernel : Array[Double] = Array::make(size * size, 0.0)

  let dx = @math.cos(angle)
  let dy = @math.sin(angle)

  for i in 0..<length {
    let t = (i - length / 2).to_double()
    let ox = round_to_int(t * dx)
    let oy = round_to_int(t * dy)
    let x = r + ox
    let y = r + oy
    if x >= 0 && x < size && y >= 0 && y < size {
      kernel[x + y * size] = kernel[x + y * size] + 1.0
    }
  }
  let sum = kernel.fold(init=0.0, fn(acc : Double, v : Double) { acc + v })
  if sum <= 0.0 {
    return self
  }
  let norm_kernel = kernel.map(fn(v) { v / sum })
  // Use generic odd-size convolution.
  self.convolve_nxn(norm_kernel, size, border)
}

///|
/// Apply an NxN convolution kernel (odd N) to RGB channels, keeping alpha from the center pixel.
pub fn Image::convolve_nxn(
  self : Image,
  kernel : Array[Double],
  size : Int,
  border : BorderMode,
) -> Image {
  self.convolve_nxn_ex(kernel, size, 1.0, 0.0, border)
}

///|
/// NxN convolution with an extra scale factor and bias: `out = acc * factor + bias`.
pub fn Image::convolve_nxn_ex(
  self : Image,
  kernel : Array[Double],
  size : Int,
  factor : Double,
  bias : Double,
  border : BorderMode,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if size <= 0 || size % 2 == 0 {
    return Image::default()
  }
  if kernel.length() != size * size {
    return Image::default()
  }
  let radius = size / 2
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut rr = 0.0
      let mut gg = 0.0
      let mut bb = 0.0
      let mut ki = 0
      for oy_i in 0..<size {
        let oy = oy_i - radius
        for ox_i in 0..<size {
          let ox = ox_i - radius
          let p = self.sample(x + ox, y + oy, border)
          let k = kernel[ki]
          rr = rr + p.r.to_double() * k
          gg = gg + p.g.to_double() * k
          bb = bb + p.b.to_double() * k
          ki += 1
        }
      }
      let center = self.pixels[idx]
      RgbaColor::{
        r: clamp_u8_f(rr * factor + bias),
        g: clamp_u8_f(gg * factor + bias),
        b: clamp_u8_f(bb * factor + bias),
        a: center.a,
      }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

fn filters_luma(p : RgbaColor) -> Double {
  (p.r.to_double() + p.g.to_double() + p.b.to_double()) / 3.0
}

fn filters_grad_edges(
  img : Image,
  gx : Array[Double],
  gy : Array[Double],
  border : BorderMode,
) -> Image {
  let w = img.width
  let h = img.heigth
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut sx = 0.0
      let mut sy = 0.0
      let mut ki = 0
      let offsets : Array[Int] = [-1, 0, 1]
      for oy in offsets {
        for ox in offsets {
          let p = img.sample(x + ox, y + oy, border)
          let lum = filters_luma(p)
          sx = sx + lum * gx[ki]
          sy = sy + lum * gy[ki]
          ki += 1
        }
      }
      let mag = @math.pow(sx * sx + sy * sy, 0.5)
      let v = clamp_u8_f(mag)
      let a = img.pixels[idx].a
      RgbaColor::{ r: v, g: v, b: v, a }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Laplacian edge response (grayscale output) on luminance, alpha preserved.
pub fn Image::laplacian(self : Image, border : BorderMode) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let k : Array[Double] = [0.0, 1.0, 0.0, 1.0, -4.0, 1.0, 0.0, 1.0, 0.0]
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      let mut acc = 0.0
      let mut ki = 0
      let offsets : Array[Int] = [-1, 0, 1]
      for oy in offsets {
        for ox in offsets {
          let p = self.sample(x + ox, y + oy, border)
          let lum = filters_luma(p)
          acc = acc + lum * k[ki]
          ki += 1
        }
      }
      let v = clamp_u8_f(filters_abs(acc))
      let a = self.pixels[idx].a
      RgbaColor::{ r: v, g: v, b: v, a }
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Prewitt edge magnitude (grayscale output) on luminance, alpha preserved.
pub fn Image::prewitt_edges(self : Image, border : BorderMode) -> Image {
  let gx : Array[Double] = [-1.0, 0.0, 1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 1.0]
  let gy : Array[Double] = [-1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
  filters_grad_edges(self, gx, gy, border)
}

///|
/// Scharr edge magnitude (grayscale output) on luminance, alpha preserved.
pub fn Image::scharr_edges(self : Image, border : BorderMode) -> Image {
  let gx : Array[Double] = [-3.0, 0.0, 3.0, -10.0, 0.0, 10.0, -3.0, 0.0, 3.0]
  let gy : Array[Double] = [-3.0, -10.0, -3.0, 0.0, 0.0, 0.0, 3.0, 10.0, 3.0]
  filters_grad_edges(self, gx, gy, border)
}

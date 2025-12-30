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

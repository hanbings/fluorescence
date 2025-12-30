///|
/// Helpers for grayscale buffers and spectrum visualization.

///|
/// Convert the image to a normalized grayscale buffer (0.0 - 1.0).
pub fn Image::to_gray_buffer(self : Image) -> Array[Double] {
  (0)
  .until(self.width * self.heigth)
  .map(fn(idx) {
    let pixel = self.pixels[idx]
    let sum = pixel.r.to_double() + pixel.g.to_double() + pixel.b.to_double()
    sum / 3.0 / 255.0
  })
  .collect()
}

///|
/// Convert an `ImageSpectrum` back into a displayable grayscale image.
pub fn ImageSpectrum::to_image(self : ImageSpectrum) -> Image {
  let pixels : Array[RgbaColor] = self.data.map(fn(v) {
    let clamped = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
    let gray_val = (clamped * 255.0).to_int().to_byte()
    RgbaColor::{ r: gray_val, g: gray_val, b: gray_val, a: 255 }
  })
  Image::{ pixels, width: self.width, heigth: self.heigth }
}

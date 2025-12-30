///|
/// Pixel-level helpers and simple color operations.

///|
/// Get pixel at (x, y). Returns `None` if out of bounds.
pub fn Image::get_pixel(self : Image, x : Int, y : Int) -> RgbaColor? {
  if x < 0 || y < 0 || x >= self.width || y >= self.heigth {
    None
  } else {
    Some(self.pixels[x + y * self.width])
  }
}

///|
/// Map all pixels with a function, preserving image dimensions.
pub fn Image::map_pixels(self : Image, f : (RgbaColor) -> RgbaColor) -> Image {
  let pixels = self.pixels.map(f)
  Image::{ pixels, width: self.width, heigth: self.heigth }
}

///|
/// Map all pixels with access to (x, y) coordinates, preserving dimensions.
pub fn Image::map_pixels_xy(
  self : Image,
  f : (Int, Int, RgbaColor) -> RgbaColor,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / w
      let x = idx - y * w
      f(x, y, self.pixels[idx])
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Convert the image to grayscale.
///
/// Each pixel's RGB components are averaged and written back to all three
/// channels, while preserving the alpha channel.
pub fn Image::to_grayscale(self : Image) -> Image {
  let pixels : Array[RgbaColor] = self.pixels.map(fn(pixel) {
    let sum : Int = pixel.r.to_int() + pixel.g.to_int() + pixel.b.to_int()
    let gray : Byte = (sum / 3).to_byte()
    RgbaColor::{ r: gray, g: gray, b: gray, a: pixel.a }
  })
  Image::{ pixels, width: self.width, heigth: self.heigth }
}

///|
/// Invert RGB channels, keeping alpha unchanged.
pub fn Image::invert_rgb(self : Image) -> Image {
  self.map_pixels(fn(p) {
    RgbaColor::{
      r: clamp_u8(255 - p.r.to_int()),
      g: clamp_u8(255 - p.g.to_int()),
      b: clamp_u8(255 - p.b.to_int()),
      a: p.a,
    }
  })
}

///|
/// Add brightness to RGB channels by `delta` (can be negative), clamped to [0, 255].
pub fn Image::adjust_brightness(self : Image, delta : Int) -> Image {
  self.map_pixels(fn(p) {
    RgbaColor::{
      r: clamp_u8(p.r.to_int() + delta),
      g: clamp_u8(p.g.to_int() + delta),
      b: clamp_u8(p.b.to_int() + delta),
      a: p.a,
    }
  })
}

///|
/// Padding and tiling utilities.

///|
/// Pad the image by adding borders around it.
///
/// New pixels are filled by sampling the source at shifted coordinates using `border`.
pub fn Image::pad(
  self : Image,
  left : Int,
  top : Int,
  right : Int,
  bottom : Int,
  border : BorderMode,
) -> Image {
  if left < 0 || top < 0 || right < 0 || bottom < 0 {
    return Image::default()
  }
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let new_w = w + left + right
  let new_h = h + top + bottom
  if new_w <= 0 || new_h <= 0 {
    return Image::default()
  }
  let total = new_w * new_h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_w
      let x = idx - y * new_w
      self.sample(x - left, y - top, border)
    })
    .collect()
  Image::{ pixels, width: new_w, heigth: new_h }
}

///|
/// Repeat the image `repeat_x` times horizontally and `repeat_y` times vertically.
pub fn Image::tile(self : Image, repeat_x : Int, repeat_y : Int) -> Image {
  if repeat_x <= 0 || repeat_y <= 0 {
    return Image::default()
  }
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let new_w = w * repeat_x
  let new_h = h * repeat_y
  let total = new_w * new_h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_w
      let x = idx - y * new_w
      let sx = x % w
      let sy = y % h
      self.pixels[sx + sy * w]
    })
    .collect()
  Image::{ pixels, width: new_w, heigth: new_h }
}

///|
/// Cropping, flipping, rotation, and resizing utilities.

///|
/// Create a cropped sub-image from the current image.
pub fn Image::crop(self : Image, x : Int, y : Int, w : Int, h : Int) -> Image {
  if w <= 0 || h <= 0 {
    return Image::default()
  }

  // Clamp the crop rectangle to the image bounds.
  let mut start_x = x
  let mut start_y = y
  if start_x < 0 {
    start_x = 0
  }
  if start_y < 0 {
    start_y = 0
  }
  let mut end_x = x + w
  let mut end_y = y + h
  if end_x > self.width {
    end_x = self.width
  }
  if end_y > self.heigth {
    end_y = self.heigth
  }

  // No overlap after clamping.
  if start_x >= end_x || start_y >= end_y {
    return Image::default()
  }
  let new_w = end_x - start_x
  let new_h = end_y - start_y
  let total = new_w * new_h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let j = idx / new_w
      let i = idx - j * new_w
      let src_x = start_x + i
      let src_y = start_y + j
      let src_idx = src_y * self.width + src_x
      self.pixels[src_idx]
    })
    .collect()
  Image::{ pixels, width: new_w, heigth: new_h }
}

///|
/// Center crop to a given size. If the requested size exceeds the image,
/// it will be clipped by `crop`.
pub fn Image::crop_center(self : Image, w : Int, h : Int) -> Image {
  let x = (self.width - w) / 2
  let y = (self.heigth - h) / 2
  self.crop(x, y, w, h)
}

///|
/// Center-crop to a target aspect ratio `(aspect_w : aspect_h)`, keeping the largest area.
pub fn Image::crop_to_aspect(
  self : Image,
  aspect_w : Int,
  aspect_h : Int,
) -> Image {
  if aspect_w <= 0 || aspect_h <= 0 {
    return Image::default()
  }
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  // Compare w/h with aspect_w/aspect_h using cross-multiplication.
  let lhs = w * aspect_h
  let rhs = h * aspect_w
  let (cw, ch) = if lhs > rhs {
    // Too wide: reduce width.
    let ch = h
    let cw = h * aspect_w / aspect_h
    (cw, ch)
  } else if lhs < rhs {
    // Too tall: reduce height.
    let cw = w
    let ch = w * aspect_h / aspect_w
    (cw, ch)
  } else {
    (w, h)
  }
  self.crop_center(cw, ch)
}

///|
/// Flip image horizontally (mirror left-right).
pub fn Image::flip_h(self : Image) -> Image {
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
      self.pixels[w - 1 - x + y * w]
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Flip image vertically (mirror top-bottom).
pub fn Image::flip_v(self : Image) -> Image {
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
      self.pixels[x + (h - 1 - y) * w]
    })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Rotate image 90 degrees clockwise.
pub fn Image::rotate90_cw(self : Image) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let new_w = h
  let new_h = w
  let total = new_w * new_h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_w
      let x = idx - y * new_w
      let ox = y
      let oy = h - 1 - x
      self.pixels[ox + oy * w]
    })
    .collect()
  Image::{ pixels, width: new_w, heigth: new_h }
}

///|
/// Rotate image 90 degrees counter-clockwise.
pub fn Image::rotate90_ccw(self : Image) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let new_w = h
  let new_h = w
  let total = new_w * new_h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_w
      let x = idx - y * new_w
      let ox = w - 1 - y
      let oy = x
      self.pixels[ox + oy * w]
    })
    .collect()
  Image::{ pixels, width: new_w, heigth: new_h }
}

///|
/// Rotate image 180 degrees.
pub fn Image::rotate180(self : Image) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  let total = w * h
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) { self.pixels[total - 1 - idx] })
    .collect()
  Image::{ pixels, width: w, heigth: h }
}

///|
/// Resize image using nearest-neighbor sampling.
pub fn Image::resize(self : Image, new_width : Int, new_heigth : Int) -> Image {
  if new_width <= 0 || new_heigth <= 0 {
    return Image::default()
  }
  let src_w = self.width
  let src_h = self.heigth
  if src_w <= 0 || src_h <= 0 {
    return Image::default()
  }
  let total = new_width * new_heigth
  let dst_pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_width
      let x = idx - y * new_width
      let sx_f = x.to_double() * src_w.to_double() / new_width.to_double()
      let sy_f = y.to_double() * src_h.to_double() / new_heigth.to_double()
      let mut sx = sx_f.to_int()
      let mut sy = sy_f.to_int()
      if sx >= src_w {
        sx = src_w - 1
      }
      if sy >= src_h {
        sy = src_h - 1
      }
      self.pixels[sx + sy * src_w]
    })
    .collect()
  Image::{ pixels: dst_pixels, width: new_width, heigth: new_heigth }
}

///|
/// Resize image using bilinear sampling.
pub fn Image::resize_bilinear(
  self : Image,
  new_width : Int,
  new_heigth : Int,
) -> Image {
  if new_width <= 0 || new_heigth <= 0 {
    return Image::default()
  }
  let src_w = self.width
  let src_h = self.heigth
  if src_w <= 0 || src_h <= 0 {
    return Image::default()
  }
  let total = new_width * new_heigth
  let dst_pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let y = idx / new_width
      let x = idx - y * new_width
      let sx = if new_width == 1 {
        0.0
      } else {
        x.to_double() * (src_w - 1).to_double() / (new_width - 1).to_double()
      }
      let sy = if new_heigth == 1 {
        0.0
      } else {
        y.to_double() * (src_h - 1).to_double() / (new_heigth - 1).to_double()
      }
      let x0 = sx.to_int()
      let y0 = sy.to_int()
      let x1 = if x0 + 1 >= src_w { src_w - 1 } else { x0 + 1 }
      let y1 = if y0 + 1 >= src_h { src_h - 1 } else { y0 + 1 }
      let tx = sx - x0.to_double()
      let ty = sy - y0.to_double()
      let p00 = self.sample(x0, y0, BorderMode::Clamp)
      let p10 = self.sample(x1, y0, BorderMode::Clamp)
      let p01 = self.sample(x0, y1, BorderMode::Clamp)
      let p11 = self.sample(x1, y1, BorderMode::Clamp)
      let lerp = fn(a : Double, b : Double, t : Double) { a + (b - a) * t }
      let r0 = lerp(p00.r.to_double(), p10.r.to_double(), tx)
      let r1 = lerp(p01.r.to_double(), p11.r.to_double(), tx)
      let g0 = lerp(p00.g.to_double(), p10.g.to_double(), tx)
      let g1 = lerp(p01.g.to_double(), p11.g.to_double(), tx)
      let b0 = lerp(p00.b.to_double(), p10.b.to_double(), tx)
      let b1 = lerp(p01.b.to_double(), p11.b.to_double(), tx)
      let a0 = lerp(p00.a.to_double(), p10.a.to_double(), tx)
      let a1 = lerp(p01.a.to_double(), p11.a.to_double(), tx)
      RgbaColor::{
        r: clamp_u8_f(lerp(r0, r1, ty)),
        g: clamp_u8_f(lerp(g0, g1, ty)),
        b: clamp_u8_f(lerp(b0, b1, ty)),
        a: clamp_u8_f(lerp(a0, a1, ty)),
      }
    })
    .collect()
  Image::{ pixels: dst_pixels, width: new_width, heigth: new_heigth }
}

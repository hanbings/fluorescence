///|
/// Color adjustment operations (threshold/gamma/contrast/etc).
fn clamp01_color(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
/// Convert image to a binary black/white image using grayscale threshold.
pub fn Image::threshold_gray(self : Image, threshold : Byte) -> Image {
  self.map_pixels(fn(p) {
    let lum = (p.r.to_int() + p.g.to_int() + p.b.to_int()) / 3
    let v = if lum >= threshold.to_int() { 255 } else { 0 }
    RgbaColor::{ r: v.to_byte(), g: v.to_byte(), b: v.to_byte(), a: p.a }
  })
}

///|
/// Posterize RGB channels into `levels` (2..256). Alpha unchanged.
pub fn Image::posterize(self : Image, levels : Int) -> Image {
  if levels < 2 {
    return Image::default()
  }
  let lv = if levels > 256 { 256 } else { levels }
  let step = 255.0 / (lv - 1).to_double()
  self.map_pixels(fn(p) {
    let q = fn(x : Byte) {
      let xf = x.to_double() / step
      let qi = round_to_int(xf) // nearest level index
      clamp_u8_f(qi.to_double() * step)
    }
    RgbaColor::{ r: q(p.r), g: q(p.g), b: q(p.b), a: p.a }
  })
}

///|
/// Gamma correction on RGB channels (gamma > 0). Alpha unchanged.
pub fn Image::gamma(self : Image, gamma : Double) -> Image {
  if gamma <= 0.0 {
    return Image::default()
  }
  let inv = 1.0 / gamma
  self.map_pixels(fn(p) {
    let f = fn(x : Byte) {
      let xn = x.to_double() / 255.0
      clamp_u8_f(@math.pow(clamp01_color(xn), inv) * 255.0)
    }
    RgbaColor::{ r: f(p.r), g: f(p.g), b: f(p.b), a: p.a }
  })
}

///|
/// Linear contrast around mid-gray (128). factor=1 keeps unchanged.
pub fn Image::contrast(self : Image, factor : Double) -> Image {
  self.map_pixels(fn(p) {
    let f = fn(x : Byte) {
      let v = (x.to_double() - 128.0) * factor + 128.0
      clamp_u8_f(v)
    }
    RgbaColor::{ r: f(p.r), g: f(p.g), b: f(p.b), a: p.a }
  })
}

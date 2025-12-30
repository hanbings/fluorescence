///|
/// Alpha utilities and image compositing.

///|
pub(all) enum BlendMode {
  /// Replace destination pixels with source pixels (where they overlap).
  Replace
  /// Alpha blend: source-over destination.
  Over
}

///|
fn clamp01_comp(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn blend_over(src : RgbaColor, dst : RgbaColor) -> RgbaColor {
  // Convert to [0,1]
  let sr = src.r.to_double() / 255.0
  let sg = src.g.to_double() / 255.0
  let sb = src.b.to_double() / 255.0
  let sa = src.a.to_double() / 255.0
  let dr = dst.r.to_double() / 255.0
  let dg = dst.g.to_double() / 255.0
  let db = dst.b.to_double() / 255.0
  let da = dst.a.to_double() / 255.0
  let out_a = sa + da * (1.0 - sa)
  if out_a <= 0.0 {
    return RgbaColor::default()
  }
  // Non-premultiplied formula.
  let out_r = (sr * sa + dr * da * (1.0 - sa)) / out_a
  let out_g = (sg * sa + dg * da * (1.0 - sa)) / out_a
  let out_b = (sb * sa + db * da * (1.0 - sa)) / out_a
  RgbaColor::{
    r: clamp_u8_f(clamp01_comp(out_r) * 255.0),
    g: clamp_u8_f(clamp01_comp(out_g) * 255.0),
    b: clamp_u8_f(clamp01_comp(out_b) * 255.0),
    a: clamp_u8_f(clamp01_comp(out_a) * 255.0),
  }
}

///|
/// Multiply alpha by `factor` in [0.0, 1.0].
pub fn Image::opacity(self : Image, factor : Double) -> Image {
  let f = clamp01_comp(factor)
  self.map_pixels(fn(p) {
    let a = clamp_u8_f(p.a.to_double() * f)
    RgbaColor::{ r: p.r, g: p.g, b: p.b, a }
  })
}

///|
/// Replace alpha channel with a constant `alpha`.
pub fn Image::replace_alpha(self : Image, alpha : Byte) -> Image {
  self.map_pixels(fn(p) { RgbaColor::{ r: p.r, g: p.g, b: p.b, a: alpha } })
}

///|
/// Convert to premultiplied alpha (RGB := RGB * A/255).
pub fn Image::premultiply_alpha(self : Image) -> Image {
  self.map_pixels(fn(p) {
    let a = p.a.to_double() / 255.0
    RgbaColor::{
      r: clamp_u8_f(p.r.to_double() * a),
      g: clamp_u8_f(p.g.to_double() * a),
      b: clamp_u8_f(p.b.to_double() * a),
      a: p.a,
    }
  })
}

///|
/// Convert from premultiplied alpha back to straight alpha.
pub fn Image::unpremultiply_alpha(self : Image) -> Image {
  self.map_pixels(fn(p) {
    if p.a == 0 {
      RgbaColor::default()
    } else {
      let a = p.a.to_double() / 255.0
      RgbaColor::{
        r: clamp_u8_f(p.r.to_double() / a),
        g: clamp_u8_f(p.g.to_double() / a),
        b: clamp_u8_f(p.b.to_double() / a),
        a: p.a,
      }
    }
  })
}

///|
/// Draw `src` onto `self` at position `(dx, dy)` and return a new image.
///
/// Pixels outside destination bounds are ignored.
pub fn Image::blit(
  self : Image,
  src : Image,
  dx : Int,
  dy : Int,
  mode : BlendMode,
) -> Image {
  let w = self.width
  let h = self.heigth
  if w <= 0 || h <= 0 {
    return Image::default()
  }
  if src.width <= 0 || src.heigth <= 0 {
    return self
  }
  let out_pixels = self.pixels
  for sy in 0..<src.heigth {
    let y = dy + sy
    if y < 0 || y >= h {
      continue
    }
    for sx in 0..<src.width {
      let x = dx + sx
      if x < 0 || x >= w {
        continue
      }
      let s = src.pixels[sx + sy * src.width]
      let di = x + y * w
      match mode {
        BlendMode::Replace => out_pixels[di] = s
        BlendMode::Over => out_pixels[di] = blend_over(s, out_pixels[di])
      }
    }
  }
  Image::{ pixels: out_pixels, width: w, heigth: h }
}

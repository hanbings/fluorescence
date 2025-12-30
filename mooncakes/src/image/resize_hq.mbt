///|
/// High-quality resize algorithms: area (downscale) and Lanczos3 (general).
fn resize_hq_clamp_int(v : Int, lo : Int, hi : Int) -> Int {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn resize_hq_sample_clamp(img : Image, x : Int, y : Int) -> RgbaColor {
  let sx = resize_hq_clamp_int(x, 0, img.width - 1)
  let sy = resize_hq_clamp_int(y, 0, img.heigth - 1)
  img.pixels[sx + sy * img.width]
}

///|
/// Resize image using area resampling (best for downscaling).
///
/// If either dimension is upscaled, this falls back to bilinear to avoid
/// nearest-like artifacts.
pub fn Image::resize_area(
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
  // Only use area when downscaling in both dimensions.
  if new_width >= src_w || new_heigth >= src_h {
    return self.resize_bilinear(new_width, new_heigth)
  }
  let scale_x = src_w.to_double() / new_width.to_double()
  let scale_y = src_h.to_double() / new_heigth.to_double()
  let total = new_width * new_heigth
  let pixels : Array[RgbaColor] = (0)
    .until(total)
    .map(fn(idx) {
      let dy = idx / new_width
      let dx = idx - dy * new_width
      let sx0 = dx.to_double() * scale_x
      let sx1 = (dx + 1).to_double() * scale_x
      let sy0 = dy.to_double() * scale_y
      let sy1 = (dy + 1).to_double() * scale_y
      let x_start = sx0.to_int()
      let x_end = sx1.to_int() + 1
      let y_start = sy0.to_int()
      let y_end = sy1.to_int() + 1
      let mut sum_w = 0.0
      let mut r = 0.0
      let mut g = 0.0
      let mut b = 0.0
      let mut a = 0.0
      for sy in y_start..<y_end {
        let py0 = sy.to_double()
        let py1 = (sy + 1).to_double()
        let oy = (if py1 < sy1 { py1 } else { sy1 }) -
          (if py0 > sy0 { py0 } else { sy0 })
        if oy <= 0.0 {
          continue
        }
        for sx in x_start..<x_end {
          let px0 = sx.to_double()
          let px1 = (sx + 1).to_double()
          let ox = (if px1 < sx1 { px1 } else { sx1 }) -
            (if px0 > sx0 { px0 } else { sx0 })
          if ox <= 0.0 {
            continue
          }
          let w = ox * oy
          let p = resize_hq_sample_clamp(self, sx, sy)
          sum_w = sum_w + w
          r = r + p.r.to_double() * w
          g = g + p.g.to_double() * w
          b = b + p.b.to_double() * w
          a = a + p.a.to_double() * w
        }
      }
      if sum_w <= 0.0 {
        resize_hq_sample_clamp(self, dx, dy)
      } else {
        RgbaColor::{
          r: clamp_u8_f(r / sum_w),
          g: clamp_u8_f(g / sum_w),
          b: clamp_u8_f(b / sum_w),
          a: clamp_u8_f(a / sum_w),
        }
      }
    })
    .collect()
  Image::{ pixels, width: new_width, heigth: new_heigth }
}

///|
fn resize_hq_sinc(x : Double) -> Double {
  if x == 0.0 {
    1.0
  } else {
    let pix = @math.PI * x
    @math.sin(pix) / pix
  }
}

///|
fn resize_hq_lanczos(x : Double, a : Double) -> Double {
  let ax = if x < 0.0 { -x } else { x }
  if ax >= a {
    0.0
  } else {
    resize_hq_sinc(x) * resize_hq_sinc(x / a)
  }
}

///|
fn resize_hq_resample_x_lanczos3(
  src : Image,
  new_width : Int,
) -> Array[RgbaColor] {
  let src_w = src.width
  let src_h = src.heigth
  let a = 3.0
  let scale = new_width.to_double() / src_w.to_double()
  let scale_f = if scale < 1.0 { scale } else { 1.0 }
  let support = if scale < 1.0 { a / scale } else { a }
  let total = new_width * src_h
  (0)
  .until(total)
  .map(fn(idx) {
    let y = idx / new_width
    let x = idx - y * new_width

    // Map destination pixel center to source coordinate.
    let src_x = (x.to_double() + 0.5) *
      src_w.to_double() /
      new_width.to_double() -
      0.5
    let start = (src_x - support).to_int() - 1
    let end = (src_x + support).to_int() + 1
    let mut wsum = 0.0
    let mut rr = 0.0
    let mut gg = 0.0
    let mut bb = 0.0
    let mut aa = 0.0
    for ix in start..<end {
      let t = (src_x - ix.to_double()) * scale_f
      let w = resize_hq_lanczos(t, a) * scale_f
      if w == 0.0 {
        continue
      }
      let p = resize_hq_sample_clamp(src, ix, y)
      wsum = wsum + w
      rr = rr + p.r.to_double() * w
      gg = gg + p.g.to_double() * w
      bb = bb + p.b.to_double() * w
      aa = aa + p.a.to_double() * w
    }
    if wsum == 0.0 {
      resize_hq_sample_clamp(src, round_to_int(src_x), y)
    } else {
      RgbaColor::{
        r: clamp_u8_f(rr / wsum),
        g: clamp_u8_f(gg / wsum),
        b: clamp_u8_f(bb / wsum),
        a: clamp_u8_f(aa / wsum),
      }
    }
  })
  .collect()
}

///|
fn resize_hq_resample_y_lanczos3(
  tmp : Array[RgbaColor],
  tmp_w : Int,
  tmp_h : Int,
  new_h : Int,
) -> Array[RgbaColor] {
  let a = 3.0
  let scale = new_h.to_double() / tmp_h.to_double()
  let scale_f = if scale < 1.0 { scale } else { 1.0 }
  let support = if scale < 1.0 { a / scale } else { a }
  let sample_tmp = fn(x : Int, y : Int) -> RgbaColor {
    let sx = resize_hq_clamp_int(x, 0, tmp_w - 1)
    let sy = resize_hq_clamp_int(y, 0, tmp_h - 1)
    tmp[sx + sy * tmp_w]
  }
  let total = tmp_w * new_h
  (0)
  .until(total)
  .map(fn(idx) {
    let y = idx / tmp_w
    let x = idx - y * tmp_w
    let src_y = (y.to_double() + 0.5) * tmp_h.to_double() / new_h.to_double() -
      0.5
    let start = (src_y - support).to_int() - 1
    let end = (src_y + support).to_int() + 1
    let mut wsum = 0.0
    let mut rr = 0.0
    let mut gg = 0.0
    let mut bb = 0.0
    let mut aa = 0.0
    for iy in start..<end {
      let t = (src_y - iy.to_double()) * scale_f
      let w = resize_hq_lanczos(t, a) * scale_f
      if w == 0.0 {
        continue
      }
      let p = sample_tmp(x, iy)
      wsum = wsum + w
      rr = rr + p.r.to_double() * w
      gg = gg + p.g.to_double() * w
      bb = bb + p.b.to_double() * w
      aa = aa + p.a.to_double() * w
    }
    if wsum == 0.0 {
      sample_tmp(x, round_to_int(src_y))
    } else {
      RgbaColor::{
        r: clamp_u8_f(rr / wsum),
        g: clamp_u8_f(gg / wsum),
        b: clamp_u8_f(bb / wsum),
        a: clamp_u8_f(aa / wsum),
      }
    }
  })
  .collect()
}

///|
/// Resize image using separable Lanczos3 filtering.
pub fn Image::resize_lanczos3(
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
  if new_width == src_w && new_heigth == src_h {
    return self
  }
  let tmp = resize_hq_resample_x_lanczos3(self, new_width)
  let dst = resize_hq_resample_y_lanczos3(tmp, new_width, src_h, new_heigth)
  Image::{ pixels: dst, width: new_width, heigth: new_heigth }
}

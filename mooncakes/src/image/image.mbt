///|
pub(all) struct RgbaColor {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Default, Eq, Show)

///|
pub(all) struct Image {
  pixels : Array[RgbaColor]
  width : Int
  heigth : Int
} derive(Default, Eq, Show)

///|
/// Computes the Euclidean distance between two RGBA colors.
///
/// # Parameters
/// - `color_a`: The first RGBA color.
/// - `color_b`: The second RGBA color.
///
/// # Returns
/// Returns the Euclidean distance between `color_a` and `color_b` in the RGBA color space,
/// calculated using the following formula:
///
/// ```math
/// d = sqrt((r1 - r2)^2 + (g1 - g2)^2 + (b1 - b2)^2 + (a1 - a2)^2)
/// ```
///
/// - If the result is `0.0`, the colors are identical.
/// - A larger value indicates a greater color difference.
///
pub fn RgbaColor::calc_dist(color_a : RgbaColor, color_b : RgbaColor) -> Float {
  let dr = (color_a.r - color_b.r).to_float().pow(2)
  let dg = (color_a.g - color_b.g).to_float().pow(2)
  let db = (color_a.b - color_b.b).to_float().pow(2)
  let da = (color_a.a - color_b.a).to_float().pow(2)
  (dr + dg + db + da).sqrt()
}

///|
/// Create a cropped sub-image from the current image.
///
/// The crop rectangle is defined by its top-left corner `(x, y)` and size
/// `(w, h)`. Any part of the rectangle that lies outside the image bounds
/// will be automatically clipped.
///
/// # Parameters
/// - `x`, `y`: Top-left coordinate of the crop region.
/// - `w`, `h`: Width and height of the crop region.
///
/// # Returns
/// A new `Image` containing the cropped region. If the requested region does
/// not intersect the source image at all (or `w <= 0` / `h <= 0`), this
/// returns `Image::default()`.
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
/// Convert the image to grayscale.
///
/// Each pixel's RGB components are averaged and written back to all three
/// channels, while preserving the alpha channel.
///
/// This keeps the same image dimensions and only changes pixel values.
pub fn Image::to_grayscale(self : Image) -> Image {
  let pixels : Array[RgbaColor] = self.pixels.map(fn(pixel) {
    // Compute average in a wider integer type to avoid byte overflow.
    let sum : Int = pixel.r.to_int() + pixel.g.to_int() + pixel.b.to_int()
    let gray : Byte = (sum / 3).to_byte()
    RgbaColor::{ r: gray, g: gray, b: gray, a: pixel.a }
  })
  Image::{ pixels, width: self.width, heigth: self.heigth }
}

///|
/// Resize image using nearest-neighbor sampling.
///
/// This is a simple and fast method: each destination pixel picks the
/// nearest source pixel in the original image.
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
/// Grayscale frequency-domain representation of an image.
///
/// This is currently a **placeholder** for future FFT-based processing.
/// The `data` field stores a flattened `width * heigth` grayscale buffer
/// in row-major order.
pub(all) struct ImageSpectrum {
  width : Int
  heigth : Int
  data : Array[Double]
} derive(Default, Show)

///|
/// Convert the image to a normalized grayscale buffer (0.0 - 1.0).
///
/// This is intended as a helper for future FFT operations.
pub fn Image::to_gray_buffer(self : Image) -> Array[Double] {
  (0)
  .until(self.width * self.heigth)
  .map(fn(idx) {
    let pixel = self.pixels[idx]
    // Simple average in [0, 255] then normalize to [0.0, 1.0].
    let sum = pixel.r.to_double() + pixel.g.to_double() + pixel.b.to_double()
    sum / 3.0 / 255.0
  })
  .collect()
}

///|

///|
/// Convert an `ImageSpectrum` back into a displayable grayscale image.
///
/// Assumes `data` is a normalized grayscale buffer (0.0 - 1.0) in row-major
/// order. Values are clamped to [0.0, 1.0] before mapping to [0, 255].
pub fn ImageSpectrum::to_image(self : ImageSpectrum) -> Image {
  let pixels : Array[RgbaColor] = self.data.map(fn(v) {
    let clamped = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
    let gray_val = (clamped * 255.0).to_int().to_byte()
    RgbaColor::{ r: gray_val, g: gray_val, b: gray_val, a: 255 }
  })
  Image::{ pixels, width: self.width, heigth: self.heigth }
}

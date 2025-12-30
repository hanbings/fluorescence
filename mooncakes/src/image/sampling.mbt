///|
/// Border sampling behavior for operations that access pixels out of bounds.
pub(all) enum BorderMode {
  /// Treat out-of-bounds pixels as transparent black.
  Zero
  /// Clamp coordinates to the nearest edge pixel.
  Clamp
  /// Reflect coordinates at the image edges (mirror).
  Reflect
  /// Fill out-of-bounds with a constant color.
  Constant(RgbaColor)
}

///|
fn reflect_coord(c0 : Int, max : Int) -> Int {
  if max <= 0 {
    return 0
  }
  let mut c = c0
  // Reflect into [0, max-1].
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
pub fn Image::sample(
  self : Image,
  x : Int,
  y : Int,
  border : BorderMode,
) -> RgbaColor {
  match border {
    BorderMode::Zero =>
      if x < 0 || y < 0 || x >= self.width || y >= self.heigth {
        RgbaColor::default()
      } else {
        self.pixels[x + y * self.width]
      }
    BorderMode::Clamp => {
      let mut sx = x
      let mut sy = y
      if sx < 0 {
        sx = 0
      } else if sx >= self.width {
        sx = self.width - 1
      }
      if sy < 0 {
        sy = 0
      } else if sy >= self.heigth {
        sy = self.heigth - 1
      }
      self.pixels[sx + sy * self.width]
    }
    BorderMode::Reflect => {
      let sx = reflect_coord(x, self.width)
      let sy = reflect_coord(y, self.heigth)
      self.pixels[sx + sy * self.width]
    }
    BorderMode::Constant(c) =>
      if x < 0 || y < 0 || x >= self.width || y >= self.heigth {
        c
      } else {
        self.pixels[x + y * self.width]
      }
  }
}

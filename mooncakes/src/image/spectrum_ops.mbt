///|
/// Spectrum utilities (fftshift/log scaling).
fn mod_pos(x : Int, m : Int) -> Int {
  let r = x % m
  if r < 0 {
    r + m
  } else {
    r
  }
}

///|
fn shift2d(
  width : Int,
  heigth : Int,
  data : Array[Double],
  sx : Int,
  sy : Int,
) -> Array[Double] {
  let n = width * heigth
  if width <= 0 || heigth <= 0 || data.length() != n {
    return Array::make(0, 0.0)
  }
  (0)
  .until(n)
  .map(fn(idx) {
    let y = idx / width
    let x = idx - y * width
    let ox = mod_pos(x + sx, width)
    let oy = mod_pos(y + sy, heigth)
    data[ox + oy * width]
  })
  .collect()
}

///|
/// Shift the zero-frequency component to the center of the spectrum.
pub fn ImageSpectrum::fftshift(self : ImageSpectrum) -> ImageSpectrum {
  let sx = self.width / 2
  let sy = self.heigth / 2
  let data = shift2d(self.width, self.heigth, self.data, sx, sy)
  ImageSpectrum::{ width: self.width, heigth: self.heigth, data }
}

///|
/// Inverse of `fftshift`.
pub fn ImageSpectrum::ifftshift(self : ImageSpectrum) -> ImageSpectrum {
  let sx = (self.width + 1) / 2
  let sy = (self.heigth + 1) / 2
  let data = shift2d(self.width, self.heigth, self.data, sx, sy)
  ImageSpectrum::{ width: self.width, heigth: self.heigth, data }
}

///|
/// Apply log scaling to spectrum data for visualization.
///
/// `out = log(1 + v * scale) / log(1 + scale)` for v in [0, 1].
pub fn ImageSpectrum::log_magnitude(
  self : ImageSpectrum,
  scale : Double,
) -> ImageSpectrum {
  let s = if scale <= 0.0 { 1.0 } else { scale }
  let denom = @math.log10(1.0 + s)
  let data = if denom <= 0.0 {
    self.data
  } else {
    self.data.map(fn(v) {
      let vv = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
      @math.log10(1.0 + vv * s) / denom
    })
  }
  ImageSpectrum::{ width: self.width, heigth: self.heigth, data }
}

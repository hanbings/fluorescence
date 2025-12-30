///|
/// Histogram and quality metrics.

///|
pub struct Histogram {
  r : Array[Int]
  g : Array[Int]
  b : Array[Int]
  a : Array[Int]
} derive(Show)

///|
fn hist_init() -> Array[Int] {
  Array::make(256, 0)
}

///|
/// Compute per-channel histogram (256 bins each).
pub fn Image::histogram_rgba(self : Image) -> Histogram {
  let hr = hist_init()
  let hg = hist_init()
  let hb = hist_init()
  let ha = hist_init()
  for p in self.pixels {
    hr[p.r.to_int()] += 1
    hg[p.g.to_int()] += 1
    hb[p.b.to_int()] += 1
    ha[p.a.to_int()] += 1
  }
  Histogram::{ r: hr, g: hg, b: hb, a: ha }
}

///|
/// Peak signal-to-noise ratio (PSNR) in dB over RGBA channels.
///
/// Returns `None` if sizes mismatch.
pub fn psnr(a : Image, b : Image) -> Double? {
  if a.width != b.width ||
    a.heigth != b.heigth ||
    a.pixels.length() != b.pixels.length() {
    return None
  }
  let n = a.pixels.length()
  if n == 0 {
    return None
  }
  let mut sum = 0.0
  for i in 0..<n {
    let pa = a.pixels[i]
    let pb = b.pixels[i]
    let dr = pa.r.to_double() - pb.r.to_double()
    let dg = pa.g.to_double() - pb.g.to_double()
    let db = pa.b.to_double() - pb.b.to_double()
    let da = pa.a.to_double() - pb.a.to_double()
    sum = sum + dr * dr + dg * dg + db * db + da * da
  }
  // 4 channels per pixel.
  let mse = sum / (n.to_double() * 4.0)
  if mse <= 0.0 {
    return Some(999.0)
  }
  let max_i = 255.0
  Some(10.0 * @math.log10(max_i * max_i / mse))
}

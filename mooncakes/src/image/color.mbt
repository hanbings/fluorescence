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
  let dr = Float::from_byte(color_a.r - color_b.r).pow(2)
  let dg = Float::from_byte(color_a.g - color_b.g).pow(2)
  let db = Float::from_byte(color_a.b - color_b.b).pow(2)
  let da = Float::from_byte(color_a.a - color_b.a).pow(2)
  (dr + dg + db + da).sqrt()
}



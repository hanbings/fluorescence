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
/// # Example
/// ```moonbit
/// let c1 = RgbaColor(255, 0, 0, 255)  // Pure red
/// let c2 = RgbaColor(0, 0, 255, 255)  // Pure blue
/// let dist = calc_dist(c1, c2)
/// print(dist)  // Output: 360.62
/// ```
pub fn RgbaColor::calc_dist(color_a : RgbaColor, color_b : RgbaColor) -> Float {
  let dr = (color_a.r - color_b.r).to_float().pow(2)
  let dg = (color_a.g - color_b.g).to_float().pow(2)
  let db = (color_a.b - color_b.b).to_float().pow(2)
  let da = (color_a.a - color_b.a).to_float().pow(2)
  (dr + dg + db + da).sqrt()
}

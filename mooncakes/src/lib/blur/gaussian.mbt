///|
pub fn fast_blur(
  buffer : Array[UInt],
  x0 : UInt,
  y0 : UInt,
  x1 : UInt,
  y1 : UInt,
  width : UInt
) -> Unit {
  let kernel_size = 3
  let radius = kernel_size / 2
  for y in y0..=y1 {
    for x in x0..=x1 {
      let mut sum_r = 0
      let mut sum_g = 0
      let mut sum_b = 0
      let mut count = 0
      for ky in -radius..=radius {
        for kx in -radius..=radius {
          let nx = x + kx.reinterpret_as_uint()
          let ny = y + ky.reinterpret_as_uint()
          if nx >= 0 && ny >= 0 && nx < width && ny >= 0 {
            let pixel = buffer[ny.reinterpret_as_int() *
              width.reinterpret_as_int() +
              nx.reinterpret_as_int()]
            sum_r += pixel.reinterpret_as_int() & 0xFF
            sum_g += (pixel.reinterpret_as_int() >> 8) & 0xFF
            sum_b += (pixel.reinterpret_as_int() >> 16) & 0xFF
            count += 1
          }
        }
      }
      let r = (sum_r / count) & 0xFF
      let g = (sum_g / count) & 0xFF
      let b = (sum_b / count) & 0xFF
      buffer[y.reinterpret_as_int() * width.reinterpret_as_int() +
      x.reinterpret_as_int()] = (r | (g << 8) | (b << 16) | 0xFF000000).reinterpret_as_uint()
    }
  }
}

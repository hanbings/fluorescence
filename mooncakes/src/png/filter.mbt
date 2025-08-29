///|
pub fn unfilter_all(
  ihdr : Ihdr,
  raw : Array[Byte],
) -> Array[Byte] raise PngError {
  let sp = samples_per_pixel(ihdr.color_type)
  let rb = rowbytes(ihdr.width, sp, ihdr.bit_depth).reinterpret_as_int() // number of bytes per line (excluding filter bytes)
  let bpp = bpp_bytes(sp, ihdr.bit_depth).reinterpret_as_int() // bytes per pixel (across channels)
  let stride = 1 + rb // the span of each line containing the filter bytes.
  let height = ihdr.height.reinterpret_as_int()
  if raw.length() != stride * height {
    raise Inflate("decompressed size does not match expected scanlines")
  }
  let out : Array[Byte] = Array::make(rb * height, 0)
  let prev_row : Array[Byte] = Array::make(rb, 0)
  for y in 0..<height {
    let src_off = y * stride
    let filter = raw[src_off]
    let in_off = src_off + 1
    let dst_off = y * rb
    match filter {
      0 =>
        // None
        for x in 0..<rb {
          out[dst_off + x] = raw[in_off + x]
        }
      1 =>
        // Sub
        for x in 0..<rb {
          let a = if x >= bpp { out[dst_off + x - bpp] } else { 0 }
          out[dst_off + x] = raw[in_off + x] + a
        }
      2 =>
        // Up
        for x in 0..<rb {
          let b = prev_row[x]
          out[dst_off + x] = raw[in_off + x] + b
        }
      3 =>
        // Average
        for x in 0..<rb {
          let a = if x >= bpp { out[dst_off + x - bpp] } else { 0 }
          let b = prev_row[x]
          let avg = ((a + b) / 2) & 0xFF
          out[dst_off + x] = raw[in_off + x] + avg
        }
      4 =>
        // Paeth
        for x in 0..<rb {
          let a = if x >= bpp { out[dst_off + x - bpp] } else { 0 }
          let b = prev_row[x]
          let c = if x >= bpp { prev_row[x - bpp] } else { 0 }
          out[dst_off + x] = raw[in_off + x] + paeth(a, b, c)
        }
      _ => raise Inflate("unknown filter")
    }

    // prev_row = current row.
    for x in 0..<rb {
      prev_row[x] = out[dst_off + x]
    }
  }
  out
}

///|
pub fn unfilter_row_inplace(
  line : Array[Byte],
  prev : Array[Byte],
  filter : Byte,
  bpp : UInt,
) -> Unit raise PngError {
  match filter {
    0 => ()
    1 =>
      // Sub
      for x in 0..<line.length() {
        let a = if x >= bpp.reinterpret_as_int() {
          line[x - bpp.reinterpret_as_int()]
        } else {
          0
        }
        line[x] = line[x] + a
      }
    2 =>
      // Up
      for x in 0..<line.length() {
        let b = if !prev.is_empty() { prev[x] } else { 0 }
        line[x] = line[x] + b
      }
    3 =>
      // Average
      for x in 0..<line.length() {
        let a = if x >= bpp.reinterpret_as_int() {
          line[x - bpp.reinterpret_as_int()]
        } else {
          0
        }
        let b = if !prev.is_empty() { prev[x] } else { 0 }
        line[x] = line[x] + (a + b) / 2
      }
    4 =>
      // Paeth
      for x in 0..<line.length() {
        let a = if x >= bpp.reinterpret_as_int() {
          line[x - bpp.reinterpret_as_int()]
        } else {
          0
        }
        let b = if !prev.is_empty() { prev[x] } else { 0 }
        let c = if !prev.is_empty() && x >= bpp.reinterpret_as_int() {
          prev[x - bpp.reinterpret_as_int()]
        } else {
          0
        }
        line[x] = line[x] + paeth(a, b, c)
      }
    _ => raise Inflate("unknown filter")
  }
}

///|
pub fn paeth(a : Byte, b : Byte, c : Byte) -> Byte {
  let a = a.to_int()
  let b = b.to_int()
  let c = c.to_int()
  let p = a + b - c
  let pa = (p - a).abs()
  let pb = (p - b).abs()
  let pc = (p - c).abs()
  if pa <= pb && pa <= pc {
    a.to_byte()
  } else if pb <= pc {
    b.to_byte()
  } else {
    c.to_byte()
  }
}

///|
pub fn samples_per_pixel(ct : ColorType) -> UInt {
  match ct {
    ColorType::Grayscale => 1
    ColorType::Rgb => 3
    ColorType::Palette => 1
    ColorType::GrayscaleAlpha => 2
    ColorType::Rgba => 4
  }
}

///|
pub fn rowbytes(width : UInt, sp : UInt, bit_depth : Byte) -> UInt {
  let bits = width * sp * bit_depth.to_uint()
  (bits + 7) / 8
}

///|
pub fn bpp_bytes(sp : UInt, bit_depth : Byte) -> UInt {
  let bits_per_pixel = sp * bit_depth.to_uint()
  (bits_per_pixel + 7) / 8 // <8-bit -> 1
}

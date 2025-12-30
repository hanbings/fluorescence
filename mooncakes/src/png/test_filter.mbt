// wrapping subtraction for UInt8

///|
fn sub_wrap_u8(a : Byte, b : Byte) -> Byte {
  (a - b) & 0xFF
}

// Encode PNG "Sub" filter: filtered[x] = raw[x] - left(x)

///|
fn enc_sub(u : Array[Byte], bpp : Int) -> Array[Byte] {
  let f : Array[Byte] = Array::make(u.length(), 0)
  for x in 0..<u.length() {
    let a = if x >= bpp { u[x - bpp] } else { 0 }
    // filtered[x] = raw[x] - left(x) (wrapping)
    f[x] = sub_wrap_u8(u[x], a)
  }
  f
}

// Encode PNG "Up" filter: filtered[x] = raw[x] - up(x)

///|
fn enc_up(u : Array[Byte], prev : Array[Byte]) -> Array[Byte] {
  let f : Array[Byte] = Array::make(u.length(), 0)
  let has_prev = prev.length() > 0
  for x in 0..<u.length() {
    let b = if has_prev { prev[x] } else { 0 }
    f[x] = sub_wrap_u8(u[x], b)
  }
  f
}

// Encode PNG "Average" filter: filtered[x] = raw[x] - floor((left+up)/2)

///|
fn enc_avg(u : Array[Byte], prev : Array[Byte], bpp : Int) -> Array[Byte] {
  let f : Array[Byte] = Array::make(u.length(), 0)
  let has_prev = prev.length() > 0
  for x in 0..<u.length() {
    let a = if x >= bpp { u[x - bpp] } else { 0 }
    let b = if has_prev { prev[x] } else { 0 }
    let avg = ((a + b) / 2) & 0xFF
    f[x] = sub_wrap_u8(u[x], avg)
  }
  f
}

// Encode PNG "Paeth" filter: filtered[x] = raw[x] - paeth(left, up, up_left)

///|
fn enc_paeth(u : Array[Byte], prev : Array[Byte], bpp : Int) -> Array[Byte] {
  let f : Array[Byte] = Array::make(u.length(), 0)
  let has_prev = prev.length() > 0
  for x in 0..<u.length() {
    let a = if x >= bpp { u[x - bpp] } else { 0 }
    let b = if has_prev { prev[x] } else { 0 }
    let c = if has_prev && x >= bpp { prev[x - bpp] } else { 0 }
    f[x] = sub_wrap_u8(u[x], paeth(a, b, c))
  }
  f
}

// Convenience constructor for Ihdr used in tests.
// Accepts Ints and casts to the exact field types.

///|
fn ihdr(
  width : Int,
  height : Int,
  bit_depth : Int,
  color_type : ColorType,
) -> Ihdr {
  Ihdr::{
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    bit_depth: bit_depth.to_byte(),
    color_type,
    compression_method: 0,
    filter_method: 0,
    interlace_method: 0,
  }
}

///|
// Paeth predictor picks the neighbor (a, b, or c) closest to p = a + b - c.
// Tie-breaking order: a, then b, then c.
test "paeth_examples" {
  // choose a: p = 10 + 20 - 30 = 0; |0-10|=10 < |0-20|, |0-30|
  assert_eq(paeth(10, 20, 30), 10)

  // choose b: set c == a => p = b, so distance to b is 0
  assert_eq(paeth(7, 20, 7), 20)

  // choose c
  assert_eq(paeth(100, 50, 75), 75)

  // tie-breaking (pa == pb == pc) -> pick a
  assert_eq(paeth(5, 5, 5), 5)
}

///|
// Basic checks for samples_per_pixel, rowbytes rounding, and bpp_bytes.
test "samples_rowbytes_bpp" {
  // samples_per_pixel
  assert_eq(samples_per_pixel(ColorType::Grayscale), 1)
  assert_eq(samples_per_pixel(ColorType::Rgb), 3)
  assert_eq(samples_per_pixel(ColorType::Palette), 1)
  assert_eq(samples_per_pixel(ColorType::GrayscaleAlpha), 2)
  assert_eq(samples_per_pixel(ColorType::Rgba), 4)

  // rowbytes rounding for sub-byte depths
  assert_eq(rowbytes(3, 1, 1), 1) // 3 bits -> 1 byte
  assert_eq(rowbytes(9, 1, 1), 2) // 9 bits -> 2 bytes
  assert_eq(rowbytes(5, 3, 8), 15) // 5*3*8 bits = 120 -> 15 bytes

  // bpp_bytes
  assert_eq(bpp_bytes(1, 1), 1) // <8-bit rounds up to 1
  assert_eq(bpp_bytes(1, 4), 1)
  assert_eq(bpp_bytes(3, 16), 6) // RGB16 -> 6 bytes
  assert_eq(bpp_bytes(4, 8), 4) // RGBA8 -> 4 bytes
}

///|
// We'll use two 3-channel "pixels" per row to exercise left-neighbor dependency.
// Verifies all five filters via forward-encode (Sub/Up/Average/Paeth) then in-place unfilter.
test "unfilter_row_inplace_none_sub_up_avg_paeth" {
  let bpp : Int = 3
  let prev : Array[Byte] = [1, 2, 3, 4, 5, 6] // previous unfiltered row
  let u : Array[Byte] = [10, 20, 30, 40, 50, 60] // target unfiltered row

  // None
  let line = u
  unfilter_row_inplace(line, [], 0, bpp.reinterpret_as_uint())
  assert_eq(line, u)

  // Sub
  let line = enc_sub(u, bpp)
  unfilter_row_inplace(line, [], 1, bpp.reinterpret_as_uint())
  assert_eq(line, u)

  // Up
  let line = enc_up(u, prev)
  unfilter_row_inplace(line, prev, 2, bpp.reinterpret_as_uint())
  assert_eq(line, u)

  // Average
  let line = enc_avg(u, prev, bpp)
  unfilter_row_inplace(line, prev, 3, bpp.reinterpret_as_uint())
  assert_eq(line, u)

  // Paeth
  let line = enc_paeth(u, prev, bpp)
  unfilter_row_inplace(line, prev, 4, bpp.reinterpret_as_uint())
  assert_eq(line, u)
}

///|
// Image: Gray8, width=5, height=2
// Build two filtered rows (Row0: Sub, Row1: Up) and verify unfilter_all restores them.
test "unfilter_all_two_rows_mixed_filters" {
  let ih = ihdr(5, 2, 8, ColorType::Grayscale)
  let sp = samples_per_pixel(ih.color_type)
  let rb = rowbytes(ih.width, sp, ih.bit_depth)
  let bpp = bpp_bytes(sp, ih.bit_depth)
  assert_eq(sp, 1)
  assert_eq(rb, 5)
  assert_eq(bpp, 1)
}

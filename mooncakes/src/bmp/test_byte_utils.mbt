///|
test "test_read_u16le_basic" {
  let buf : Array[Byte] = [0x34, 0x12]
  assert_eq(read_u16le(buf, 0), 0x1234)
}

///|
test "test_read_u32le_basic" {
  let buf : Array[Byte] = [0x78, 0x56, 0x34, 0x12]
  assert_eq(read_u32le(buf, 0), 0x12345678)
}

///|
test "test_read_u32le_basic" {
  let buf : Array[Byte] = [0x01, 0x00, 0x00, 0x00]
  assert_eq(read_i32le(buf, 0), 1)
  // 0x007FFFFF -> 8388607
  let buf2 : Array[Byte] = [0xFF, 0xFF, 0x7F, 0x00]
  assert_eq(read_i32le(buf2, 0), 0x007F_FFFF)
}

///|
/// mask_to_shift: basic and edge cases
test "test_mask_to_shift_basic" {
  // LSB at bit 0 => 0 trailing zeros
  assert_eq(mask_to_shift(0x00000001), 0)

  // 0xF0 = 11110000b -> 4 trailing zeros
  assert_eq(mask_to_shift(0x000000F0), 4)

  // Only bit 31 set -> 31 trailing zeros
  assert_eq(mask_to_shift(0x80000000), 31)

  // mask == 0 : by our implementation returns 0
  assert_eq(mask_to_shift(0x00000000), 0)
}

///|
/// mask_bit_count: popcount on various patterns
test "test_mask_bit_count_basic" {
  assert_eq(mask_bit_count(0x00000000), 0)
  assert_eq(mask_bit_count(0x00000001), 1)
  // 11110000b
  assert_eq(mask_bit_count(0x000000F0), 4)
  assert_eq(mask_bit_count(0x80000000), 1)
  // 32 ones
  assert_eq(mask_bit_count(0xFFFFFFFF), 32)
  // alternating 0101...
  assert_eq(mask_bit_count(0x55555555), 16)
}

///|
/// expand_bits: n-bit -> 8-bit scaling (round-to-nearest)
test "test_expand_bits_scaling" {
  // bits == 0 -> 0
  assert_eq(expand_bits(0, 0), 0)

  // bits >= 8 -> low 8 bits
  assert_eq(expand_bits(0xAB, 8), 0xAB)
  // 0x123 & 0xFF = 0x23
  assert_eq(expand_bits(0x123, 12), 0x23)

  // 5-bit cases: max -> 255, zero -> 0, mid -> ~132
  // formula: ((x * 255 + max/2) / max)
  assert_eq(expand_bits(0, 5), 0)
  assert_eq(expand_bits(31, 5), 255)
  // (16*255+15)/31 = 132
  assert_eq(expand_bits(16, 5), 132)

  // 6-bit cases: max -> 255, zero -> 0, mid(32) -> ~130
  assert_eq(expand_bits(0, 6), 0)
  assert_eq(expand_bits(63, 6), 255)
  // (32*255+31)/63 = 130
  assert_eq(expand_bits(32, 6), 130)
}

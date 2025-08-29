///|
test "basic_8bit_read" {
  let data : Array[Byte] = [0x12, 0xFF]
  let r = new_sample_reader(data, 8)
  assert_eq(r.next_u16(), Some(0x12))
  assert_eq(r.next_u16(), Some(0xFF))
  assert_eq(r.next_u16(), None)
}

///|
test "16bit_big_endian_and_eof_test" {
  // Code builds u16 as ((hi)<<8)|lo, i.e. big-endian per pair
  let data : Array[Byte] = [0x12, 0x34, 0xAB] // 2.5 bytes
  let r = new_sample_reader(data, 16)
  assert_eq(r.next_u16(), Some(0x1234))
  // Only one byte (0xAB) left -> not enough for another u16
  assert_eq(r.next_u16(), None)
  let data2 : Array[Byte] = [0xBE, 0xEF, 0xCA, 0xFE]
  let r2 = new_sample_reader(data2, 16)
  assert_eq(r2.next_u16(), Some(0xBEEF))
  assert_eq(r2.next_u16(), Some(0xCAFE))
  assert_eq(r2.next_u16(), None)
}

///|
test "read_1bit_msb_first_within_byte_test" {
  let data : Array[Byte] = [0xac]
  let r = new_sample_reader(data, 1)
  let expected = [1, 0, 1, 0, 1, 1, 0, 0]
  for e in expected {
    assert_eq(r.next_u16(), Some(e.to_uint16()))
  }
  assert_eq(r.next_u16(), None)
}

///|
// Groups are [7:6], [5:4], [3:2], [1:0], then next byte, etc.
// 0xAC = 1010_1100 -> 10(2),10(2),11(3),00(0)
// 0x53 = 0101_0011 -> 01(1),01(1),00(0),11(3)
test "read_2bit_msb_first_cross_byte" {
  let data : Array[Byte] = [0xac, 0x53]
  let r = new_sample_reader(data, 2)
  let expected = [2, 2, 3, 0, 1, 1, 0, 3]
  for e in expected {
    assert_eq(r.next_u16(), Some(e.to_uint16()))
  }
  assert_eq(r.next_u16(), None)
}

///|
// 4-bit: high nibble then low nibble
// 0xAB -> 0xA, 0xB; 0x0F -> 0x0, 0xF
test "read_4bit_nibbles_msb_first" {
  let data : Array[Byte] = [0xab, 0x0f]
  let r = new_sample_reader(data, 4)
  assert_eq(r.next_u16(), Some(0xA))
  assert_eq(r.next_u16(), Some(0xB))
  assert_eq(r.next_u16(), Some(0x0))
  assert_eq(r.next_u16(), Some(0xF))
  assert_eq(r.next_u16(), None)
}

///|
// After consuming 8 one-bit samples from the first byte,
// reader should advance to the next byte automatically.
// Byte0 = 0b1000_0001 (0x81) -> [1,0,0,0,0,0,0,1]
// Byte1 = 0b0110_0000 (0x60) -> [0,1,1,0,0,0,0,0]
test "read_1bit_across_multiple_bytes" {
  let data : Array[Byte] = [0x81, 0x60]
  let r = new_sample_reader(data, 1)
  let expected = [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0]
  for e in expected {
    assert_eq(r.next_u16(), Some(e.to_uint16()))
  }
  assert_eq(r.next_u16(), None)
}

///|
// Empty input should immediately return None for any bit depth
test "empty_input_returns_none" {
  let data1 : Array[Byte] = []
  let r1 = new_sample_reader(data1, 8)
  assert_eq(r1.next_u16(), None)
  let data2 : Array[Byte] = []
  let r2 = new_sample_reader(data2, 1)
  assert_eq(r2.next_u16(), None)
  let data3 : Array[Byte] = []
  let r3 = new_sample_reader(data3, 16)
  assert_eq(r3.next_u16(), None)
}

///|
// Sub-byte depths should run out cleanly when a byte is exactly consumed
test "partial_byte_runs_out_cleanly_for_subbyte_depths" {
  // With 4-bit depth, one byte yields exactly 2 samples; next is None.
  let data : Array[Byte] = [0xf0]
  let r = new_sample_reader(data, 4)
  assert_eq(r.next_u16(), Some(0xF))
  assert_eq(r.next_u16(), Some(0x0))
  assert_eq(r.next_u16(), None)

  // With 2-bit depth, one byte yields exactly 4 samples.
  // 0b1101_0010 -> 11(3), 01(1), 00(0), 10(2)
  let data2 : Array[Byte] = [0xd2] // 0b1101_0010
  let r = new_sample_reader(data2, 2)
  assert_eq(r.next_u16(), Some(3))
  assert_eq(r.next_u16(), Some(1))
  assert_eq(r.next_u16(), Some(0))
  assert_eq(r.next_u16(), Some(2))
  assert_eq(r.next_u16(), None)
}

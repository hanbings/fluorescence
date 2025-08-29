///|
test "basic_bits_read_test" {
  let buf : Array[Byte] = [0xac, 0x03]
  let br = new_bit_reader(buf, 0)

  // read 3 bits first: the lowest three bits of 0xAC 100b = 4
  assert_eq(br.read_bits(3), 4)

  // read 5 more bits: what remains is 0xAC >> 3 = 0x15, and the lower 5 bits are 0x15 = 21
  assert_eq(br.read_bits(5), 21)

  // read 2 bits: Least significant two bits from 0x03 11b = 3
  assert_eq(br.read_bits(2), 3)
  br.align_to_byte()
  assert_eq(br.consumed(), 2)
}

///|
test "cross_byte_read_test" {
  // construct two bytes to verify that the straddle-byte read is correct
  // 0xe5 = 1110_0101b -> first 8 bits of the LSB stream: 1,0,1,0,0,1,1,1
  // 0x43 = 0100_0011b -> first 8 bits of the LSB stream: 1,1,0,0,0,0,1,0
  let buf : Array[Byte] = [0xe5, 0x43]
  let br = new_bit_reader(buf, 0)

  // read 4 bits in sequence: 0b0101 = 5
  assert_eq(br.read_bits(4), 0b0101)

  // read 4 more bits: 0b1110 = 14
  assert_eq(br.read_bits(4), 0b1110)

  // read 4 more bits (enter the second byte): 0b0011 = 3
  assert_eq(br.read_bits(4), 0b0011)

  // last 4 bits: 0b0100 = 4
  assert_eq(br.read_bits(4), 0b0100)
}

///|
test "align_and_consumed_test" {
  let buf : Array[Byte] = [0xff, 0xff]
  let br = new_bit_reader(buf, 0)

  // read 5 bits -> 8 bits will be loaded into the bitbuf first. 
  // after removing 5 bits, 3 bits will be left in the bitbuf.
  // consumed = pos - (bitlen/8) = 1 - 0 = 1
  let _ = br.read_bits(5)
  assert_eq(br.consumed(), 1)

  // after byte alignment, it should still be 1
  br.align_to_byte()
  assert_eq(br.consumed(), 1)

  // read another complete byte
  let _ = br.read_bits(8)
  assert_eq(br.consumed(), 2)
}

///|
test "start_offset_respected_test" {
  // start reading from offset 1, the first byte should be skipped
  let buf : Array[Byte] = [0xaa, 0x55, 0xff]
  let br = new_bit_reader(buf, 1)

  // read the full 8 bits and get the second byte 0x55
  assert_eq(br.read_bits(8), 0x55)
  br.align_to_byte()

  // consumed should be 2 (pos=2, bitlen=0)
  assert_eq(br.consumed(), 2)
}

///|
test "many_small_reads_sum_to_bytes_test" {
  // multiple small-bit-width reads should be equivalent to sequential reads.
  // buf = [0b1010_1100, 0b0000_0011]
  let buf : Array[Byte] = [0xac, 0x03]
  let br = new_bit_reader(buf, 0)

  // read 1 bit 8 times and reassemble into the LSB-first sequence of 0xAC to represent the same value 0xAC
  let mut v = 0
  for i in 0..<8 {
    let bit = br.read_bits(1)
    v = v | (bit.reinterpret_as_int() << i)
  }
  assert_eq(v, 0xAC)

  // read the full 8 bits again and it should be 0x03
  let mut v2 = 0
  for i in 0..<8 {
    let bit = br.read_bits(1)
    v2 = v2 | (bit.reinterpret_as_int() << i)
  }
  assert_eq(v2, 0x03)
  br.align_to_byte()
  assert_eq(br.consumed(), 2)
}

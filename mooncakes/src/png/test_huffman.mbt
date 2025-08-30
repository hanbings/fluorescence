// Pack a sequence of bits (0/1) into bytes for an LSB-first BitReader:
// first bit -> bit 0, second -> bit 1, ..., flush every 8 bits.

///|
fn pack_bits_lsb(bits : Array[Int]) -> Array[Byte] {
  let out : Array[Byte] = Array::new()
  let mut cur : Byte = 0
  let mut cnt : Int = 0
  for b in bits {
    if b != 0 {
      cur = cur | (1 << cnt)
    }
    cnt = cnt + 1
    if cnt == 8 {
      out.push(cur & 0xFF)
      cur = 0
      cnt = 0
    }
  }
  if cnt > 0 {
    out.push(cur & 0xFF)
  }
  out
}

///|
/// Code lengths (for symbols 0..3): [1, 2, 3, 3]
/// Canonical (MSB-first):
///   sym0: '0', sym1: '10', sym2: '110', sym3: '111'
test "decode_canonical_small_test" {
  let h = build_huffman([1, 2, 3, 3])

  // Sequence: 0,1,2,3,0,2
  // Bits (time order): 0 | 10 | 110 | 111 | 0 | 110
  let bits : Array[Int] = [0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0]
  let bytes = pack_bits_lsb(bits)
  let br = new_bit_reader(bytes, 0)
  assert_eq(h.decode_huffman(br), 0)
  assert_eq(h.decode_huffman(br), 1)
  assert_eq(h.decode_huffman(br), 2)
  assert_eq(h.decode_huffman(br), 3)
  assert_eq(h.decode_huffman(br), 0)
  assert_eq(h.decode_huffman(br), 2)
}

///|
/// Ensure we cross byte boundaries in the bitstream.
/// Using same tree: [1,2,3,3] -> codes: 0, 10, 110, 111
test "decode_crosses_byte_boundaries_test" {
  // Make longer sequence to ensure we cross at least one byte boundary in the bitstream.
  // Use same small tree: [1,2,3,3] -> codes: 0, 10, 110, 111
  let h = build_huffman([1, 2, 3, 3])

  // Sequence: 3,2,1,0,3,2,1,0 (bits: 111|110|10|0|111|110|10|0)
  // Time-order bit list:
  let bits = [1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0]
  let bytes = pack_bits_lsb(bits)
  let br = new_bit_reader(bytes, 0)
  let expected = [3, 2, 1, 0, 3, 2, 1, 0]
  for e in expected {
    assert_eq(h.decode_huffman(br), e.to_byte())
  }
}

///|
/// Four symbols all with length 3 -> canonical codes: 000,001,010,011 for 0..3.
test "decode_all_len3_equal_test" {
  // Four symbols all with length 3.
  // Canonical codes: 000, 001, 010, 011 for syms 0..3
  let h = build_huffman([3, 3, 3, 3])

  // Decode 3,2,1,0 -> bits: 011 | 010 | 001 | 000
  // Time-order bits:
  let bits = [0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0]
  let bytes = pack_bits_lsb(bits)
  let br = new_bit_reader(bytes, 0)
  assert_eq(h.decode_huffman(br), 3)
  assert_eq(h.decode_huffman(br), 2)
  assert_eq(h.decode_huffman(br), 1)
  assert_eq(h.decode_huffman(br), 0)
}

///|
/// Valid lengths per Kraft: [1,3,3,3,4,4].
/// Canonical (MSB-first):
///   0->0, 3->110, 1->100, 2->101, 4->1110, 5->1111
test "decode_with_many_symbols_and_mixed_lengths_test" {
  // Use a valid length set (Kraft sum == 1)
  // symbols 0..5 => lengths [1,3,3,3,4,4]
  let h = build_huffman([1, 3, 3, 3, 4, 4])

  // We'll decode the sequence: [0, 3, 1, 2, 4, 5]
  // Canonical codes (MSB-first):
  //   0 -> 0
  //   3 -> 110
  //   1 -> 100
  //   2 -> 101
  //   4 -> 1110
  //   5 -> 1111
  let bits = [0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1]
  let bytes = pack_bits_lsb(bits)
  let br = new_bit_reader(bytes, 0)
  assert_eq(h.decode_huffman(br), 0)
  assert_eq(h.decode_huffman(br), 3)
  assert_eq(h.decode_huffman(br), 1)
  assert_eq(h.decode_huffman(br), 2)
  assert_eq(h.decode_huffman(br), 4)
  assert_eq(h.decode_huffman(br), 5)
}

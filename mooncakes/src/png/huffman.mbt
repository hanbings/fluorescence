///|
pub struct Huffman {
  first_code : Array[Int]
  first_sym : Array[Int]
  max_bits : UInt
  symbols : Array[Byte]
  count_per_len : Array[Int]
}

///|
pub fn build_huffman(code_lengths : Array[Byte]) -> Huffman raise PngError {
  let bl_count = Array::make(16, 0)
  let mut max_bits = 0U
  for l in code_lengths {
    if l > 15 {
      raise Inflate("code length > 15")
    }
    if l > 0 {
      bl_count[l.to_int()] += 1
      if l > max_bits.to_byte() {
        max_bits = l.to_uint()
      }
    }
  }
  if max_bits == 0 {
    raise Inflate("all code lengths zero")
  }
  let first_code = Array::make(16, 0)
  let mut code = 0
  for bits in 1..=15 {
    code = (code + bl_count[bits - 1]) << 1
    first_code[bits] = code
  }
  let first_sym = Array::make(16, 0)
  let mut sum = 0
  for bits in 1..=15 {
    first_sym[bits] = sum
    sum += bl_count[bits]
  }
  let symbols : Array[Byte] = Array::make(code_lengths.length(), 0)
  let next = Array::make(16, 0)
  for bits in 1..=15 {
    next[bits] = first_sym[bits]
  }
  for sym, len in code_lengths.iter() {
    let len = len
    if len != 0 {
      let idx = next[len.to_int()]
      symbols[idx] = sym.to_byte()
      next[len.to_int()] += 1
    }
  }
  let count_per_len = Array::make(16, 0)
  for bits in 1..=15 {
    count_per_len[bits] = bl_count[bits]
  }
  Huffman::{ first_code, first_sym, max_bits, symbols, count_per_len }
}

///|
pub fn Huffman::decode_huffman(
  self : Huffman,
  br : BitReader,
) -> Byte raise PngError {
  let mut code = 0
  for len in 1..=self.max_bits.reinterpret_as_int() {
    let bit = br.read_bits(1)
    code = (code << 1) | bit.reinterpret_as_int()
    let first = self.first_code[len]
    let count = self.count_per_len[len]
    if count > 0 {
      let c = code
      if c >= first && c < first + count {
        let idx = self.first_sym[len] + (c - first)
        return self.symbols[idx]
      }
    }
  }
  raise Inflate("invalid Huffman code")
}

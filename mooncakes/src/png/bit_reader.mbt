///|
pub struct BitReader {
  buf : Array[Byte]
  mut pos : UInt64
  mut bitbuf : UInt64
  mut bitlen : UInt
}

///|
pub fn new_bit_reader(buf : Array[Byte], start : UInt64) -> BitReader {
  BitReader::{ buf, pos: start, bitbuf: 0, bitlen: 0 }
}

///|
pub fn ensure_bits(self : BitReader, n : UInt) -> Unit raise PngError {
  while self.bitlen < n {
    if self.pos >= self.buf.length().reinterpret_as_uint().to_uint64() {
      raise Inflate("unexpected EOF in bitstream")
    }
    let b = self.buf[self.pos.to_int()].to_uint64()
    self.bitbuf = self.bitbuf | (b << self.bitlen.reinterpret_as_int())
    self.pos += 1
    self.bitlen += 8
  }
}

///|
pub fn read_bits(self : BitReader, n : UInt) -> UInt raise PngError {
  self.ensure_bits(n)
  let mask = (1U << n.reinterpret_as_int()) - 1U
  let val = self.bitbuf & mask.to_uint64()
  self.bitbuf = self.bitbuf >> n.reinterpret_as_int()
  self.bitlen = self.bitlen - n
  val.to_uint()
}

///|
pub fn align_to_byte(self : BitReader) -> Unit {
  let drop = self.bitlen % 8
  self.bitbuf = self.bitbuf >> drop.reinterpret_as_int()
  self.bitlen = self.bitlen - drop
}

///|
pub fn consumed(self : BitReader) -> UInt noraise {
  let back_bytes = self.bitlen / 8
  let res = self.pos - back_bytes.to_uint64()
  res.to_uint()
}

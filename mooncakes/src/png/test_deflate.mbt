///|
/// Construct a "stored (uncompressed)" zlib data stream:
/// - CMF = 0x78 (CM=8, CINFO=7)
/// - FLG = 0x01 (FCHECK divisible by 31, FDICT=0)
/// Followed by a final block (bfinal=1, btype=00).
pub fn make_zlib_stored(data : Array[Byte]) -> Array[Byte] {
  let v : Array[Byte] = Array::new()

  // Zlib header: 0x78 0x01 (common, modulo-31 satisfied)
  v.push(0x78)
  v.push(0x01)

  // Uncompressed block header (bit order LSB-first):
  // BFINAL=1, BTYPE=00 => lower 3 bits = 0b001 => 0x01
  v.push(0x01)

  // After align_to_byte, LEN and NLEN are read as little-endian
  let len : UInt16 = data.length().to_uint16()
  let nlen : UInt16 = 0xFFFF ^ len
  v.push((len & 0x00FF).to_byte())
  v.push((len >> 8).to_byte())
  v.push((nlen & 0x00FF).to_byte())
  v.push((nlen >> 8).to_byte())
  println(v)

  // Raw data payload
  for b in data {
    v.push(b)
  }

  // Adler32 checksum (big-endian)
  let ad = adler32(data)
  v.push(((ad >> 24) & 0xFF).to_byte())
  v.push(((ad >> 16) & 0xFF).to_byte())
  v.push(((ad >> 8) & 0xFF).to_byte())
  v.push((ad & 0xFF).to_byte())
  v
}

///|
test "stored_empty_test" {
  // zlib "stored" stream for empty payload
  let z = make_zlib_stored(Array::new())

  // If your inflate_deflate returns a plain tuple:
  let (out, consumed) = inflate_deflate(z)

  // out should be empty
  assert_eq(out.length(), 0)

  // 2(header) + 1(btype byte) + 4(LEN/NLEN) + 0(data) + 4(adler) = 11
  assert_eq(consumed, 11)

  // All bytes should be consumed
  assert_eq(consumed, z.length().reinterpret_as_uint())
}

///|
test "stored_hello_test" {
  let z = make_zlib_stored(['h', 'e', 'l', 'l', 'o'])
  let (out, consumed) = inflate_deflate(z)
  assert_eq(out, ['h', 'e', 'l', 'l', 'o'])
  assert_eq(consumed, 16)
  assert_eq(consumed, z.length().reinterpret_as_uint())
}

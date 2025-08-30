///|
pub fn uint32_from_be_bytes(bytes : Array[Byte]) -> UInt {
  let b0 : UInt = bytes[0].to_uint()
  let b1 : UInt = bytes[1].to_uint()
  let b2 : UInt = bytes[2].to_uint()
  let b3 : UInt = bytes[3].to_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
/// Read little-endian u16 at given offset.
/// Combines two bytes into a 16-bit unsigned integer.
pub fn read_u16le(buf : Array[Byte], off : Int) -> UInt {
  let b0 : UInt = buf[off].to_uint()
  let b1 : UInt = buf[off + 1].to_uint()
  (b1 << 8) | b0
}

///|
/// Read little-endian u32 at given offset.
/// Combines four bytes into a 32-bit unsigned integer.
pub fn read_u32le(buf : Array[Byte], off : Int) -> UInt {
  let b0 : UInt = buf[off].to_uint()
  let b1 : UInt = buf[off + 1].to_uint()
  let b2 : UInt = buf[off + 2].to_uint()
  let b3 : UInt = buf[off + 3].to_uint()
  (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
}

///|
/// Read little-endian i32 at given offset.
/// Assembles 4 bytes as unsigned, then reinterprets as signed 32-bit.
/// Performs sign extension when the highest bit is set.
pub fn read_i32le(buf : Array[Byte], off : Int) -> Int {
  // Build unsigned 32-bit value first
  let u : UInt = read_u32le(buf, off)

  // Check sign bit (bit 31). If set, extend sign to Int.
  if (u & 0x80000000) != 0 {
    // Convert to Int64, then shift to propagate the sign bit
    let v64 : Int = u.reinterpret_as_int()
    let signed32 = v64 << 32 >> 32
    signed32
  } else {
    // Safe to reinterpret directly if sign bit is not set
    u.reinterpret_as_int()
  }
}

///|
/// Return the number of trailing zero bits in `mask`.
/// NOTE: For mask == 0, this returns 0 (Rust would return 32).
pub fn mask_to_shift(mask : UInt) -> UInt {
  let mut shift : UInt = 0
  let mut m = mask
  // Count zeros until we meet the first set bit
  while (m & 1) == 0 && m != 0 {
    shift = shift + 1
    m = m >> 1
  }
  shift
}

///|
/// Count the number of set bits (population count) in `mask`.
/// Uses Kernighan's algorithm: repeatedly clear the lowest set bit.
pub fn mask_bit_count(mask : UInt) -> UInt {
  let mut cnt : UInt = 0
  let mut m = mask
  while m != 0 {
    m = m & (m - 1)
    cnt = cnt + 1
  }
  cnt
}

///|
/// Expand an `n`-bit component to 8-bit by scaling (e.g., 5-bit -> 8-bit).
/// When `bits == 0` returns 0. When `bits >= 8`, returns the low 8 bits of `v`.
pub fn expand_bits(v : UInt, bits : Int) -> Byte {
  if bits <= 0 {
    return 0
  }
  if bits >= 8 {
    return (v & 0xFF).to_byte()
  }
  let max : UInt = (1 << bits) - 1
  let x : UInt = v & max
  // Round to nearest: (x * 255 + max/2) / max
  ((x * 255 + max / 2) / max).to_byte()
}

///|
pub fn uint32_from_be_bytes(bytes : Array[Byte]) -> UInt {
  let b0 : UInt = bytes[0].to_uint()
  let b1 : UInt = bytes[1].to_uint()
  let b2 : UInt = bytes[2].to_uint()
  let b3 : UInt = bytes[3].to_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

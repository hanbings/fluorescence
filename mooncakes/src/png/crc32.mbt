pub fn crc32_table() -> Array[UInt] {
  let table = Array::make(256, 0U)
  
  for index in 0..<256 {
    let mut c = index.reinterpret_as_uint();
    for _ in 0..<8 {
      c = if(c & 1) != 0 {
        0xEDB88320 ^ (c >> 1)
      } else {
        c >> 1
      }
    }
    table[index] = c
  }
  
  table
}

pub fn crc32(bytes: Array[UInt], table?: Array[UInt]) -> UInt {
  let mut c: UInt = 0xffff_ffff
  let table = table.unwrap_or_else(fn() { crc32_table() })

  for byte in bytes {
    let index = (( c ^ byte) & 0xFF)
    c = table[index.reinterpret_as_int()] ^ (c >> 8) 
  }

  c ^ 0xffff_ffff
}
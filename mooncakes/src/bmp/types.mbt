///|
pub(all) struct Bmp {
  width : Int
  height : Int
  pixels : Array[Byte]
}

///|
pub struct BmpFileHeader {
  file_size : UInt
  reserved_1 : UInt
  reserved_2 : UInt
  off_bits : UInt
}

///|
/// BITMAPINFOHEADER (>= 40 bytes). We also read V3/V4/V5 masks if present.
pub struct BmpInfoHeader {
  // header size
  size : UInt
  width : Int
  // negative => top-down
  height : Int
  planes : UInt
  bit_count : UInt
  compression : UInt
  size_image : UInt
  x_pels_per_meter : Int
  y_pels_per_meter : Int
  clr_used : UInt
  clr_important : UInt
  // optional bitfields (when compression==3 or header >= 56 bytes)
  r_mask : Int
  g_mask : Int
  b_mask : Int
  a_mask : Int
}

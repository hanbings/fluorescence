///|
pub struct SampleReader {
  data : Array[Byte]
  bit_depth : Byte
  mut bit_pos : Byte
  mut pos : UInt
}

///|
pub fn new_sample_reader(data : Array[Byte], bit_depth : Byte) -> SampleReader {
  SampleReader::{ data, bit_depth, bit_pos: 0, pos: 0 }
}

///|
pub fn next_u16(self : SampleReader) -> UInt16? {
  match self.bit_depth {
    8 =>
      if self.pos >= self.data.length().reinterpret_as_uint() {
        None
      } else {
        let v = self.data[self.pos.reinterpret_as_int()].to_uint16()
        self.pos += 1
        Some(v)
      }
    16 =>
      if self.pos + 1 >= self.data.length().reinterpret_as_uint() {
        None
      } else {
        let v = (self.data[self.pos.reinterpret_as_int()].to_uint16() << 8) |
          self.data[self.pos.reinterpret_as_int() + 1].to_uint16()
        self.pos += 2
        Some(v)
      }
    1 | 2 | 4 => {
      if self.pos >= self.data.length().reinterpret_as_uint() {
        return None
      }
      let bp = self.bit_depth
      if self.bit_pos == 0 {
        self.bit_pos = 8
      }
      let shift = self.bit_pos - bp
      let mask = (1U << bp.to_int()) - 1
      let v = ((self.data[self.pos.reinterpret_as_int()] >> shift.to_int()) &
      mask.to_byte()).to_uint16()
      self.bit_pos -= bp
      if self.bit_pos == 0 {
        self.pos += 1
      }
      Some(v)
    }
    _ => None
  }
}

///|
struct VecReader {
  data : Array[Byte]
  mut pos : Int
}

///|
fn vec_reader_read(self : VecReader, buf : Ref[Array[Byte]]) -> Int {
  // EOF if cursor is at or beyond the end
  if self.pos >= self.data.length() {
    return 0
  }

  // n = min(available, capacity)
  let available : Int = self.data.length() - self.pos
  let n : Int = @cmp.minimum(buf.val.length(), available)

  // Copy byte-by-byte: buf[i] = data[pos + i]
  for i in 0..<n {
    buf.val[i] = self.data[self.pos + i]
  }

  // Advance cursor
  self.pos += n
  n
}

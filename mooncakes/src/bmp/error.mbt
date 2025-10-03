///|
suberror BmpError {
  // input too short
  Short
  // invalid signature (expected 'BM')
  BadSignature
  // "unsupported DIB header size: {0}
  UnsupportedDib(UInt)
  // unsupported bpp: {0}
  UnsupportedBpp(UInt)
  // unsupported compression: {0}
  UnsupportedCompression(UInt)
  // pixel array out of bounds
  OutOfBounds
  // bitfields masks missing/invalid
  BadBitfields
  // integer overflow
  IntOverflow
}

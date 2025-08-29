///|
pub struct BadChunkCrc {
  chunk_type : Array[Byte]
  expected : UInt
  actual : UInt
}

///|
pub struct ZlibAdlerMismatch {
  expected : UInt
  actual : UInt
}

///|
suberror PngError {
  Io(Error)
  InvalidSignature
  UnexpectedEof
  BadChunkCrc
  BadIhdrLength(Int)
  InvalidIhdr(String)
  NoIhdr
  NoIend
  Ordering(String)
  Unsupported(String)
  ZlibHeaderTooShort
  ZlibHeaderInvalid(String)
  ZlibAdlerMismatch
  Inflate(String)
  MissingPalette
  TrnsInvalidForColorType
  TextInvalid(String)
}

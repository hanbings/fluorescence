///|
pub(all) struct RgbaColor {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Default, Eq, Show)

///|
pub(all) struct Image {
  pixels : Array[RgbaColor]
  width : Int
  heigth : Int
} derive(Default, Eq, Show)

///|
/// Grayscale frequency-domain representation of an image.
///
/// The `data` field stores a flattened `width * heigth` normalized grayscale buffer
/// in row-major order.
pub(all) struct ImageSpectrum {
  width : Int
  heigth : Int
  data : Array[Double]
} derive(Default, Show)



///|
/// Define color type
pub enum ColorType {
  Grayscale
  Rgb
  Palette
  GrayscaleAlpha
  Rgba
}

///|
pub fn color_type_to_string(color_type : ColorType) -> String {
  match color_type {
    ColorType::Grayscale => "Grayscale"
    ColorType::Rgb => "RGB"
    ColorType::Palette => "Indexed (Palette)"
    ColorType::GrayscaleAlpha => "Grayscale+Alpha"
    ColorType::Rgba => "RGBA"
  }
}

///|
/// PNG header information.
pub struct Ihdr {
  width : UInt
  height : UInt
  bit_depth : Byte
  color_type : ColorType
  compression_method : Byte
  filter_method : Byte
  interlace_method : Byte
}

///|
/// Physical pixel size
pub struct Phys {
  pixels_per_unit_x : UInt
  pixels_per_unit_y : UInt
  unit_is_meter : Bool
}

///|
pub struct TExt {
  keyword : String
  text : String
}

///|
pub struct ZTxt {
  keyword : String
  text : String
}

///|
pub struct ITxt {
  keyword : String
  language_tag : String
  translated_keyword : String
  text : String
}

///|
/// Text Block
pub enum Text {
  TExt
  ZTxt
  ITxt
}

///|
/// ICC Profiles
pub struct Iccp {
  name : String
  compression_method : Byte
  compressed_profile : Array[Byte]
}

///|
/// Chromaticity information
pub struct ChrM {
  white_x : UInt
  white_y : UInt
  red_x : UInt
  red_y : UInt
  green_x : UInt
  green_y : UInt
  blue_x : UInt
  blue_y : UInt
}

///|
pub struct Gray {
  sample : UInt16
  bit_depth : Byte
}

///|
pub struct Rgb {
  r : UInt16
  g : UInt16
  b : UInt16
  bit_depth : Byte
}

///|
/// Transparency Information
pub enum Trns {
  Palette(Array[Byte])
  Gray
  Rgb
}

///|
/// PNG overall structure
pub struct Png {
  ihdr : Ihdr

  // color Information
  palette : Array[Array[Byte]]?
  palette_alpha : Array[Byte]?
  trns : Trns?
  bkgd_rgb16 : Array[UInt16]?
  gamma : Double?
  srgb_intent : Byte?
  chrm : ChrM?
  phys : Phys?
  text : Array[Text]
  iccp : Iccp?

  // compress image data
  idat : Array[Byte]
}

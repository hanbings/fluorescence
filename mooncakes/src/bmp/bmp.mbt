// Compression constants

///|
const BI_RGB : UInt = 0

///|
const BI_BITFIELDS : UInt = 3

///|
fn parse_file_header(buf : Array[Byte]) -> BmpFileHeader raise BmpError {
  if buf.length() < 14 {
    raise BmpError::Short
  }
  if buf[0:2] != ['B', 'M'] {
    raise BmpError::BadSignature
  }
  let file_size = read_u32le(buf, 2)
  let reserved_1 = read_u16le(buf, 6)
  let reserved_2 = read_u16le(buf, 8)
  let off_bits = read_u32le(buf, 10)
  BmpFileHeader::{ file_size, reserved_1, reserved_2, off_bits }
}

///|
fn parse_info_header(
  buf : Array[Byte],
  off : Int,
) -> BmpInfoHeader raise BmpError {
  let size = read_u32le(buf, off)
  if size < 40 {
    raise BmpError::UnsupportedDib(size)
  }
  let width = read_i32le(buf, off + 4)
  let height = read_i32le(buf, off + 8)
  let planes = read_u16le(buf, off + 12)
  let bit_count = read_u16le(buf, off + 14)
  let compression = read_u32le(buf, off + 16)
  let size_image = read_u32le(buf, off + 20)
  let x_pels_per_meter = read_i32le(buf, off + 24)
  let y_pels_per_meter = read_i32le(buf, off + 28)
  let clr_used = read_u32le(buf, off + 32)
  let clr_important = read_u32le(buf, off + 36)
  let mut r_mask = 0
  let mut g_mask = 0
  let mut b_mask = 0
  let mut a_mask = 0
  // If header is at least 56 bytes (BITMAPV3INFOHEADER), masks may follow
  if size >= 56 {
    r_mask = read_u32le(buf, off + 40).reinterpret_as_int()
    g_mask = read_u32le(buf, off + 44).reinterpret_as_int()
    b_mask = read_u32le(buf, off + 48).reinterpret_as_int()
    // may be 0
    a_mask = read_u32le(buf, off + 52).reinterpret_as_int()
  }
  BmpInfoHeader::{
    size,
    width,
    height,
    planes,
    bit_count,
    compression,
    size_image,
    x_pels_per_meter,
    y_pels_per_meter,
    clr_used,
    clr_important,
    r_mask,
    g_mask,
    b_mask,
    a_mask,
  }
}

///|
pub fn parse_bmp(data : Array[Byte]) -> Bmp raise BmpError {
  if data.length() < 54 {
    raise BmpError::Short
  }
  let fh = parse_file_header(data)
  let ih = parse_info_header(data, 14)
  if ih.planes != 1 {
    raise BmpError::UnsupportedDib(ih.planes)
  }
  if ih.bit_count != 24 && ih.bit_count != 32 {
    raise BmpError::UnsupportedBpp(ih.bit_count)
  }
  if !(ih.compression == BI_RGB || ih.compression == BI_BITFIELDS) {
    raise BmpError::UnsupportedCompression(ih.compression)
  }
  let width = ih.width
  let height_abs = ih.height.abs()
  if width <= 0 || height_abs <= 0 {
    raise BmpError::IntOverflow
  }
  let width_u = width
  let height_u = height_abs
  let bpp = ih.bit_count
  let bytes_per_pixel = bpp / 8
  // For 24-bit rows, BMP pads each row to 4-byte boundary
  let row_raw = width.to_int64() * bytes_per_pixel.to_int64()
  let row_stride = (row_raw + 3) / 4 * 4 // padded stride in file
  let pixel_off = fh.off_bits
  let need = pixel_off +
    row_stride.to_int().to_uint64().to_uint() * height_u.to_uint64().to_uint()
  if need > data.length().to_uint64().to_uint() {
    raise BmpError::OutOfBounds
  }

  // Determine masks for extraction
  let (r_mask, g_mask, b_mask, a_mask) = match (ih.compression, ih.bit_count) {
    (BI_RGB, 24) => (0x00FF0000, 0x0000FF00, 0x000000FF, 0x00000000) // file order is B,G,R
    (BI_RGB, 32) => (0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000) // BGRA common
    (BI_BITFIELDS, 32) | (BI_BITFIELDS, 24) => {
      if ih.r_mask == 0 || ih.g_mask == 0 || ih.b_mask == 0 {
        raise BmpError::BadBitfields
      }
      (ih.r_mask, ih.g_mask, ih.b_mask, ih.a_mask)
    }
    _ => raise UnsupportedCompression(ih.compression)
  }
  let r_shift = mask_to_shift(r_mask.to_uint64().to_uint())
  let g_shift = mask_to_shift(g_mask.to_uint64().to_uint())
  let b_shift = mask_to_shift(b_mask.to_uint64().to_uint())
  let a_shift = if a_mask != 0 {
    mask_to_shift(a_mask.to_uint64().to_uint())
  } else {
    0
  }
  let r_bits = mask_bit_count(r_mask.to_uint64().to_uint())
  let g_bits = mask_bit_count(g_mask.to_uint64().to_uint())
  let b_bits = mask_bit_count(b_mask.to_uint64().to_uint())
  let a_bits = mask_bit_count(a_mask.to_uint64().to_uint())
  let out : Array[Byte] = Array::make(width_u * height_u * 4, 0)
  let top_down = ih.height < 0
  for row in 0..<height_u {
    let src_row = if top_down { row } else { height_u - 1 - row }
    let src_off = pixel_off.to_int64().to_int() + src_row * row_stride.to_int()
    let dst_off = row * width_u * 4
    let src = data[src_off:src_off + row_raw.to_int()]
    if bpp == 24 {
      // B,G,R 8:8:8
      for x in 0..<width_u {
        let b = src[x * 3 + 0]
        let g = src[x * 3 + 1]
        let r = src[x * 3 + 2]
        out[dst_off + x * 4 + 0] = r
        out[dst_off + x * 4 + 1] = g
        out[dst_off + x * 4 + 2] = b
        out[dst_off + x * 4 + 3] = 0xFF
      }
    } else {
      // 32bpp
      for x in 0..<width_u {
        let px = uint32_from_be_bytes([
          src[x * 4 + 0],
          src[x * 4 + 1],
          src[x * 4 + 2],
          src[x * 4 + 3],
        ])
        let r = expand_bits(
          (px & r_mask.to_uint64().to_uint()) >> r_shift.to_int64().to_int(),
          r_bits.to_int64().to_int(),
        )
        let g = expand_bits(
          (px & g_mask.to_uint64().to_uint()) >> g_shift.to_int64().to_int(),
          g_bits.to_int64().to_int(),
        )
        let b = expand_bits(
          (px & b_mask.to_uint64().to_uint()) >> b_shift.to_int64().to_int(),
          b_bits.to_int64().to_int(),
        )
        let a = if a_mask != 0 {
          expand_bits(
            (px & a_mask.to_uint64().to_uint()) >> a_shift.to_int64().to_int(),
            a_bits.to_int64().to_int(),
          )
        } else {
          255
        }
        out[dst_off + x * 4 + 0] = r
        out[dst_off + x * 4 + 1] = g
        out[dst_off + x * 4 + 2] = b
        out[dst_off + x * 4 + 3] = a
      }
    }
  }
  Bmp::{ width: width_u, height: height_u, pixels: out }
}

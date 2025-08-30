///|
fn is_critical(typ : Array[Byte]) -> Bool {
  (typ[0] & 0x20) == 0 // uppercase => critical
}

///|
pub fn parse_png(data : Array[Byte]) -> Png raise PngError {
  let reader = VecReader::{ data, pos: 0 }
  let png_signature : Array[Byte] = [
    0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A,
  ]
  let sig : Ref[Array[Byte]] = @ref.new(Array::make(8, 0))
  let _ = reader.vec_reader_read(sig)
  if sig.val != png_signature {
    raise InvalidSignature
  }

  //
  let mut seen_ihdr = false
  let mut seen_plte = false
  let mut seen_idat = false
  let mut seen_iend = false
  let mut _seen_trns = false
  let mut ihdr_opt : Ihdr? = None
  let idat_concat : Array[Byte] = Array::new()
  let mut palette : Array[Array[Byte]]? = None
  let mut palette_alpha : Array[Byte]? = None
  let mut trns : Trns? = None
  let mut bkgd_rgb16 : Array[UInt16]? = None
  let mut gamma : Double? = None
  let mut srgb_intent : Byte? = None
  let mut chrm : ChrM? = None
  let mut phys : Phys? = None
  let text : Array[Text] = Array::new()
  let mut iccp : Iccp? = None

  //
  while true {
    let length_byte : Ref[Array[Byte]] = @ref.new([0, 0, 0, 0])
    let n = reader.vec_reader_read(length_byte)
    if n == 0 {
      break
    }
    let length = uint32_from_be_bytes(length_byte.val)

    // block type
    let typ : Ref[Array[Byte]] = @ref.new([0, 0, 0, 0])
    let _ = reader.vec_reader_read(typ)

    // block data
    let data : Ref[Array[Byte]] = @ref.new(
      Array::make(length.reinterpret_as_int(), 0),
    )
    let _ = reader.vec_reader_read(data)

    // crc data
    let crc : Ref[Array[Byte]] = @ref.new([0, 0, 0, 0])
    let _ = reader.vec_reader_read(crc)

    // crc check
    let crc_input : Array[Byte] = Array::new()
    for b in typ.val {
      crc_input.push(b)
    }
    for b in data.val {
      crc_input.push(b)
    }
    let crc_calc = crc32(crc_input.map(fn(byte) { byte.to_uint() }))
    if crc_calc != uint32_from_be_bytes(crc.val) {
      raise PngError::BadChunkCrc(BadChunkCrc::{
        chunk_type: typ.val,
        expected: crc_calc,
        actual: uint32_from_be_bytes(crc.val),
      })
    }
    match typ.val {
      ['I', 'H', 'D', 'R'] => {
        if seen_ihdr {
          raise Ordering("multiple IHDR")
        }
        if data.val.length() != 13 {
          raise BadIhdrLength(data.val.length())
        }
        let ihdr = parse_ihdr(data.val)
        seen_ihdr = true
        ihdr_opt = Some(ihdr)
      }
      ['P', 'L', 'T', 'E'] => {
        if !seen_ihdr {
          raise Ordering("PLTE before IHDR")
        }
        if seen_idat {
          raise Ordering("PLTE after IDAT")
        }
        let ihdr = ihdr_opt.or_error(PngError::NoIhdr)
        match ihdr.color_type {
          ColorType::Grayscale | ColorType::GrayscaleAlpha =>
            raise Ordering("PLTE not allowed for grayscale types")
          _ => ()
        }
        if data.val.length() % 3 != 0 || data.val.is_empty() {
          raise InvalidIhdr("PLTE length must be positive multiple of 3")
        }
        let n = data.val.length() / 3
        let pl = Array::new()
        for i in 0..<n {
          pl.push([data.val[3 * i], data.val[3 * i + 1], data.val[3 * i + 2]])
        }
        palette = Some(pl)
        seen_plte = true
      }
      ['t', 'R', 'N', 'S'] => {
        if !seen_ihdr {
          raise Ordering("tRNS before IHDR")
        }
        if seen_idat {
          raise Ordering("tRNS after IDAT")
        }
        let ihdr = ihdr_opt.or_error(PngError::NoIhdr)
        match ihdr.color_type {
          ColorType::Palette => {
            // alpha values for palette entries
            if !seen_plte {
              raise Ordering("tRNS requires PLTE before it")
            }
            let pl = palette.or_error(PngError::MissingPalette)
            if data.val.is_empty() || data.val.length() > pl.length() {
              raise InvalidIhdr("tRNS length invalid for palette")
            }
            let alpha : Array[Byte] = Array::make(pl.length(), 255)
            for i, a in data.val {
              alpha[i] = a
            }
            palette_alpha = Some(alpha)
            trns = Some(Trns::Palette(alpha))
          }
          ColorType::Grayscale => {
            if data.val.length() != 2 {
              raise InvalidIhdr("tRNS for grayscale must be 2 bytes")
            }
            let raw = uint16_from_le_bytes([data.val[0], data.val[1]])
            let v = normalize_trns_sample(raw, ihdr.bit_depth)
            trns = Some(Trns::Gray({ sample: v, bit_depth: ihdr.bit_depth }))
          }
          ColorType::Rgb => {
            if data.val.length() != 6 {
              raise InvalidIhdr("tRNS for RGB must be 6 bytes")
            }
            let r16 = uint16_from_le_bytes([data.val[0], data.val[1]])
            let g16 = uint16_from_le_bytes([data.val[2], data.val[3]])
            let b16 = uint16_from_le_bytes([data.val[4], data.val[5]])
            let r = normalize_trns_sample(r16, ihdr.bit_depth)
            let g = normalize_trns_sample(g16, ihdr.bit_depth)
            let b = normalize_trns_sample(b16, ihdr.bit_depth)
            trns = Some(Trns::Rgb({ r, g, b, bit_depth: ihdr.bit_depth }))
          }
          ColorType::GrayscaleAlpha | ColorType::Rgba =>
            raise TrnsInvalidForColorType
        }
        _seen_trns = true
      }
      ['b', 'K', 'G', 'D'] => {
        if !seen_ihdr {
          raise Ordering("bKGD before IHDR")
        }
        let ihdr = ihdr_opt.or_error(PngError::NoIhdr)
        match ihdr.color_type {
          ColorType::Palette => {
            if !seen_plte {
              raise Ordering("bKGD palette index requires PLTE first")
            }
            if data.val.length() != 1 {
              raise InvalidIhdr("bKGD for palette must be 1 byte index")
            }
            let idx = data.val[0].to_int()
            let pal = palette.or_error(PngError::MissingPalette)
            if idx >= pal.length() {
              raise InvalidIhdr("bKGD index out of palette range")
            }
            let rgb = pal[idx]
            bkgd_rgb16 = Some([
              rgb[0].to_uint16() << 8,
              rgb[1].to_uint16() << 8,
              rgb[2].to_uint16() << 8,
            ])
          } // store as 16-bit-like
          ColorType::Grayscale | ColorType::GrayscaleAlpha => {
            if data.val.length() != 2 {
              raise InvalidIhdr("bKGD grayscale must be 2 bytes")
            }
            let v = uint16_from_le_bytes([data.val[0], data.val[1]])
            bkgd_rgb16 = Some([v, v, v])
          }
          ColorType::Rgb | ColorType::Rgba => {
            if data.val.length() != 6 {
              raise InvalidIhdr("bKGD truecolor must be 6 bytes")
            }
            bkgd_rgb16 = Some([
              uint16_from_le_bytes([data.val[0], data.val[1]]),
              uint16_from_le_bytes([data.val[2], data.val[3]]),
              uint16_from_le_bytes([data.val[4], data.val[5]]),
            ])
          }
        }
      }
      ['s', 'R', 'G', 'B'] => {
        if data.val.length() != 1 {
          raise InvalidIhdr("sRGB length must be 1")
        }
        srgb_intent = Some(data.val[0])
      }
      ['g', 'A', 'M', 'A'] => {
        if data.val.length() != 4 {
          raise InvalidIhdr("gAMA length must be 4")
        }
        if srgb_intent is None {
          let val = uint32_from_be_bytes([
            data.val[0],
            data.val[1],
            data.val[2],
            data.val[3],
          ])
          if val == 0 {
            raise InvalidIhdr("gAMA value cannot be 0")
          }
          gamma = Some(val.to_double() / 100000.0)
        }
      }
      ['c', 'H', 'R', 'M'] => {
        if data.val.length() != 32 {
          raise InvalidIhdr("cHRM length must be 32")
        }
        if srgb_intent is None {
          chrm = Some(ChrM::{
            white_x: uint32_from_be_bytes([
              data.val[0],
              data.val[1],
              data.val[2],
              data.val[3],
            ]),
            white_y: uint32_from_be_bytes([
              data.val[4],
              data.val[5],
              data.val[6],
              data.val[7],
            ]),
            red_x: uint32_from_be_bytes([
              data.val[8],
              data.val[9],
              data.val[10],
              data.val[11],
            ]),
            red_y: uint32_from_be_bytes([
              data.val[12],
              data.val[13],
              data.val[14],
              data.val[15],
            ]),
            green_x: uint32_from_be_bytes([
              data.val[16],
              data.val[17],
              data.val[18],
              data.val[19],
            ]),
            green_y: uint32_from_be_bytes([
              data.val[20],
              data.val[21],
              data.val[22],
              data.val[23],
            ]),
            blue_x: uint32_from_be_bytes([
              data.val[24],
              data.val[25],
              data.val[26],
              data.val[27],
            ]),
            blue_y: uint32_from_be_bytes([
              data.val[28],
              data.val[29],
              data.val[30],
              data.val[31],
            ]),
          })
        }
      }
      ['p', 'H', 'Y', 's'] => {
        if data.val.length() != 9 {
          raise InvalidIhdr("pHYs length must be 9")
        }
        phys = Some(Phys::{
          pixels_per_unit_x: uint32_from_be_bytes([
            data.val[0],
            data.val[1],
            data.val[2],
            data.val[3],
          ]),
          pixels_per_unit_y: uint32_from_be_bytes([
            data.val[4],
            data.val[5],
            data.val[6],
            data.val[7],
          ]),
          unit_is_meter: data.val[8] == 1,
        })
      }
      ['t', 'E', 'X', 't'] => {
        let (kw, txt) = split_at_nul(data.val)
        text.push(Text::TExt({ keyword: kw, text: txt }))
      }
      ['z', 'T', 'X', 't'] => {
        // keyword, NUL, compression method(=0), compressed text(zlib)
        let (kw, rest) = split_raw_at_nul(data.val)
        if rest.is_empty() {
          raise TextInvalid("zTXt missing compression method")
        }
        let cm = rest[0]
        if cm != 0 {
          raise TextInvalid("zTXt compression method != 0")
        }
        let z = rest[1:]
        let (txt, _) = inflate_deflate(z.to_array()) // zlib stream
        let s = String::from_array(txt.to_string().to_array())
        text.push(Text::ZTxt({ keyword: kw, text: s }))
      }
      ['i', 'C', 'C', 'P'] => {
        let (name, rest) = split_raw_at_nul(data.val)
        if rest.is_empty() {
          raise InvalidIhdr("iCCP missing comp method")
        }
        let cm = rest[0]
        if cm != 0 {
          raise InvalidIhdr("iCCP compression_method != 0")
        }
        iccp = Some(Iccp::{
          name,
          compression_method: 0,
          compressed_profile: rest[1:].to_array(),
        })
      }
      ['I', 'D', 'A', 'T'] => {
        if !seen_ihdr {
          raise Ordering("IDAT before IHDR")
        }
        for b in data.val {
          idat_concat.push(b)
        }
        seen_idat = true
      }
      ['I', 'E', 'N', 'D'] => {
        if !seen_ihdr {
          raise Ordering("IEND before IHDR")
        }
        if !seen_idat {
          raise Ordering("IEND before any IDAT")
        }
        seen_iend = true
      }
      _ =>
        if is_critical(typ.val) {
          // allow known APNG critical? 
          // APNG uses acTL/fcTL/fdAT (ancillary except fdAT is ancillary too); 
          // we treat unknown critical as error
          raise Unsupported(
            "unknown critical chunk \{typ.val[0]} \{typ.val[1]} \{typ.val[2]} \{typ.val[3]}",
          )
        }
    }
  }

  //
  Png::{
    ihdr: ihdr_opt.or_error(PngError::NoIhdr),
    palette,
    palette_alpha,
    trns,
    bkgd_rgb16,
    gamma,
    srgb_intent,
    chrm,
    phys,
    text,
    iccp,
    idat: idat_concat,
  }
}

///|
pub fn parse_ihdr(data : Array[Byte]) -> Ihdr raise PngError {
  let width = uint32_from_be_bytes([data[0], data[1], data[2], data[3]])
  let height = uint32_from_be_bytes([data[4], data[5], data[6], data[7]])
  let bit_depth = data[8]
  let ct_raw = data[9]
  let compression = data[10]
  let filter = data[11]
  let interlace = data[12]
  let color_type = match ct_raw {
    0 => ColorType::Grayscale
    2 => ColorType::Rgb
    3 => ColorType::Palette
    4 => ColorType::GrayscaleAlpha
    6 => ColorType::Rgba
    _ => raise InvalidIhdr("unknown color type")
  }
  if width == 0 || height == 0 {
    raise InvalidIhdr("width/height must be > 0")
  }
  if compression != 0 {
    raise InvalidIhdr("compression_method must be 0")
  }
  if filter != 0 {
    raise InvalidIhdr("filter_method must be 0")
  }
  if interlace > 1 {
    raise InvalidIhdr("interlace_method must be 0 or 1")
  }
  let valid_bd = match color_type {
    ColorType::Grayscale =>
      match bit_depth {
        1 | 2 | 4 | 8 | 16 => true
        _ => false
      }
    ColorType::Rgb =>
      match bit_depth {
        8 | 16 => true
        _ => false
      }
    ColorType::Palette =>
      match bit_depth {
        1 | 2 | 4 | 8 => true
        _ => false
      }
    ColorType::GrayscaleAlpha =>
      match bit_depth {
        8 | 16 => true
        _ => false
      }
    ColorType::Rgba =>
      match bit_depth {
        8 | 16 => true
        _ => false
      }
  }
  if !valid_bd {
    raise InvalidIhdr("illegal bit depth for this color type")
  }
  Ihdr::{
    width,
    height,
    bit_depth,
    color_type,
    compression_method: compression,
    filter_method: filter,
    interlace_method: interlace,
  }
}

///|
fn scale_to_byte(v : UInt16, bit_depth : Byte) -> Byte {
  match bit_depth {
    8 => v.to_uint().to_byte()
    16 => (v >> 8).to_byte()
    1 | 2 | 4 => {
      let max = (1 << bit_depth.to_int()) - 1
      ((v * 255 + max.to_uint16() / 2) / max.to_uint16()).to_byte()
    }
    _ => 0
  }
}

///|
fn normalize_trns_sample(v16 : UInt16, bit_depth : Byte) -> UInt16 {
  if bit_depth == 16 {
    v16
  } else {
    let shift : Int = 16 - bit_depth.to_int()
    v16 >> shift
  }
}

///|
fn apply_trns_gray(png : Png, g_sample : UInt16) -> (Byte, Byte) {
  let ih = png.ihdr
  let g8 = scale_to_byte(g_sample, ih.bit_depth)
  let alpha = match png.trns {
    Some(trns) =>
      match trns {
        Gray(gray) => if g_sample == gray.sample { 0 } else { 255 }
        _ => 255
      }
    _ => 255
  }
  (g8, alpha.to_byte())
}

///|
fn apply_trns_rgb(
  png : Png,
  r : UInt16,
  g : UInt16,
  b : UInt16,
) -> (Byte, Byte, Byte, Byte) {
  let ih = png.ihdr
  let r8 = scale_to_byte(r, ih.bit_depth)
  let g8 = scale_to_byte(g, ih.bit_depth)
  let b8 = scale_to_byte(b, ih.bit_depth)
  let alpha = match png.trns {
    Some(trns) =>
      match trns {
        Rgb(rgb) => if r == rgb.r && g == rgb.g && b == rgb.b { 0 } else { 255 }
        _ => 255
      }
    _ => 255
  }
  (r8, g8, b8, alpha.to_byte())
}

///|
fn over(c : Byte, a : Byte, bg : Byte) -> Byte {
  let ci : Int = c.to_int()
  let ai : Int = a.to_int()
  let bgi : Int = bg.to_int()
  let res : Int = (ci * ai + bgi * (255 - ai)) / 255
  res.to_byte()
}

///|
fn split_at_nul(buf : Array[Byte]) -> (String, String) raise PngError {
  let pos = buf
    .search_by(fn(byte) { byte == 0 })
    .or_error(TextInvalid("missing NUL"))
  let key = String::from_array(buf[:pos].map(fn(byte) { byte.to_char() }))
  if key.is_empty() || key.length() > 79 {
    raise TextInvalid("keyword len invalid")
  }
  let val = String::from_array(
    buf[pos + 1:buf.length()].map(fn(byte) { byte.to_char() }),
  )
  if key.is_empty() || key.length() > 79 {
    raise TextInvalid("keyword len invalid")
  }
  (key, val)
}

///|
fn split_raw_at_nul(buf : Array[Byte]) -> (String, Array[Byte]) raise PngError {
  let pos = buf
    .search_by(fn(byte) { byte == 0 })
    .or_error(TextInvalid("missing NUL"))
  let key = String::from_array(buf[:pos].map(fn(byte) { byte.to_char() }))
  if key.is_empty() || key.length() > 79 {
    raise TextInvalid("keyword len invalid")
  }
  (key, buf[pos + 1:buf.length()].to_array())
}

///|
fn split_at_nul_from(
  buf : Array[Byte],
  start : UInt,
) -> (String, UInt) raise PngError {
  if start >= buf.length().reinterpret_as_uint() {
    raise TextInvalid("split start OOB")
  }
  let pos = buf
    .search_by(fn(byte) { byte == 0 })
    .or_error(TextInvalid("missing NUL"))
  let end = start + pos.reinterpret_as_uint()
  let s = String::from_array(
    buf[start.reinterpret_as_int():end.reinterpret_as_int()].map(fn(byte) {
      byte.to_char()
    }),
  )
  if s.is_empty() || s.length() > 79 {
    raise TextInvalid("keyword len invalid")
  }
  (s, end + 1)
}

///|
fn adler32(data : Array[Byte]) -> UInt {
  let m : UInt = 65521
  let mut a : UInt = 1
  let mut b : UInt = 0
  for x in data {
    a = (a + x.to_uint()) % m
    b = (b + a) % m
  }
  (b << 16) | a
}

///|
fn fixed_litlen_tree() -> Huffman raise PngError {
  let lens : Array[Byte] = Array::make(288, 0)
  for i in 0..=143 {
    lens[i] = 8
  }
  for i in 144..=255 {
    lens[i] = 9
  }
  for i in 256..=279 {
    lens[i] = 7
  }
  for i in 280..=287 {
    lens[i] = 8
  }
  build_huffman(lens)
}

///|
fn fixed_dist_tree() -> Huffman raise PngError {
  let lens : Array[Byte] = Array::make(32, 5)
  build_huffman(lens)
}

///|
fn read_dynamic_trees(br : BitReader) -> (Huffman, Huffman) raise PngError {
  let hlit = br.read_bits(5) + 257
  let hdist = br.read_bits(5) + 1
  let hclen = br.read_bits(4) + 4
  let order : Array[Byte] = [
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
  ]
  let clen : Array[Byte] = Array::make(19, 0)
  for i in 0..<hclen.reinterpret_as_int() {
    clen[order[i].to_int()] = br.read_bits(3).to_byte()
  }
  let clen_huff = build_huffman(clen)
  let litlen_lens : Array[Byte] = Array::make(hlit.reinterpret_as_int(), 0)
  let dist_lens : Array[Byte] = Array::make(hdist.reinterpret_as_int(), 0)
  let fill = fn(lens : Array[Byte]) -> Unit raise PngError {
    let mut i = 0
    while i < lens.length() {
      let sym = clen_huff.decode_huffman(br)
      match sym {
        0..=15 => {
          lens[i] = sym
          i += 1
        }
        16 => {
          if i == 0 {
            raise Inflate("repeat prev length at i=0")
          }
          let repeat = 3 + br.read_bits(2).reinterpret_as_int()
          let v = lens[i - 1]
          for _ in 0..<repeat {
            if i >= lens.length() {
              break
            }
            lens[i] = v
            i += 1
          }
        }
        17 => {
          let repeat = 3 + br.read_bits(3).reinterpret_as_int()
          for _ in 0..<repeat {
            if i >= lens.length() {
              break
            }
            lens[i] = 0
            i += 1
          }
        }
        18 => {
          let repeat = 11 + br.read_bits(7).reinterpret_as_int()
          for _ in 0..<repeat {
            if i >= lens.length() {
              break
            }
            lens[i] = 0
            i += 1
          }
        }
        _ => raise Inflate("invalid code length symbol")
      }
    }
  }
  fill(litlen_lens)
  fill(dist_lens)
  let litlen = build_huffman(litlen_lens)
  let dist = build_huffman(dist_lens)
  (litlen, dist)
}

///|
pub fn inflate_deflate(
  zdata : Array[Byte],
) -> (Array[Byte], UInt) raise PngError {
  let length_base = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67,
    83, 99, 115, 131, 163, 195, 227, 258,
  ]
  let length_extra = [
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5,
    5, 5, 0,
  ]
  let dist_base = [
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
    1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
  ]
  let dist_extra = [
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11,
    11, 12, 12, 13, 13,
  ]
  if zdata.length() < 2 {
    raise ZlibHeaderTooShort
  }
  let cmf = zdata[0]
  let flg = zdata[1]
  let cm = cmf & 0x0F
  let cinfo = cmf >> 4
  if cm != 8 {
    raise ZlibHeaderInvalid("CM must be 8 (DEFLATE)")
  }
  if cinfo > 7 {
    raise ZlibHeaderInvalid("CINFO > 7")
  }
  if ((cmf.to_uint16() << 8) | flg.to_uint16()) % 31 != 0 {
    raise ZlibHeaderInvalid("FCHECK modulo-31 failed")
  }
  if (flg & 0x20) != 0 {
    raise ZlibHeaderInvalid("FDICT must be 0 for PNG")
  }
  let mut br = new_bit_reader(zdata, 2)
  let mut out : Array[Byte] = Array::new()
  let fixed_ll = fixed_litlen_tree()
  let fixed_dd = fixed_dist_tree()
  while true {
    let bfinal = br.read_bits(1)
    let btype = br.read_bits(2)
    match btype {
      0 => {
        br.align_to_byte()
        let pos = br.consumed()
        if pos + 4 > zdata.length().reinterpret_as_uint() {
          raise Inflate("stored block header OOB")
        }
        let len = uint16_from_le_bytes([
          zdata[pos.reinterpret_as_int()],
          zdata[pos.reinterpret_as_int() + 1],
        ])
        let nlen = uint16_from_le_bytes([
          zdata[pos.reinterpret_as_int() + 2],
          zdata[pos.reinterpret_as_int() + 3],
        ])
        if (len ^ nlen) != 0xFFFF {
          raise Inflate("LEN ^ NLEN != 0xFFFF")
        }
        let start = pos + 4
        let end = start + len.to_uint()
        if end > zdata.length().reinterpret_as_uint() {
          raise Inflate("stored block data OOB")
        }
        out = extend_from_slice(
          zdata,
          start.reinterpret_as_int(),
          end.reinterpret_as_int(),
        )
        br = new_bit_reader(zdata, end.to_uint64())
      }
      1 | 2 => {
        let (litlen, dist) = if btype == 1 {
          (fixed_ll, fixed_dd)
        } else {
          read_dynamic_trees(br)
        }
        let sym = litlen.decode_huffman(br)
        match sym.to_uint16() {
          0..=255 => out.push(sym)
          256 => break
          257..=285 => {
            let idx = sym.to_uint16() - 257
            if idx >= 29 {
              raise Inflate("length code out of range")
            }
            let base = length_base[idx.to_int()]
            let ebits = length_extra[idx.to_int()]
            let extra = if ebits > 0 {
              br.read_bits(ebits.reinterpret_as_uint())
            } else {
              0
            }
            let length = base + extra.reinterpret_as_int()
            let dsym = dist.decode_huffman(br)
            if dsym >= 30 {
              raise Inflate("dist code out of range")
            }
            let dbase = dist_base[dsym.to_int()]
            let debits = dist_extra[dsym.to_int()]
            let dext = if debits > 0 {
              br.read_bits(debits.reinterpret_as_uint())
            } else {
              0
            }
            let distv = dbase + dext.reinterpret_as_int()
            if distv == 0 || distv > out.length() {
              raise Inflate("invalid distance")
            }
            let start = out.length() - distv
            for i in 0..<length {
              let b = out[start + i % distv]
              out.push(b)
            }
          }
          286..=287 => raise Inflate("reserved length code")
          _ => raise Inflate("invalid symbol")
        }
      }
      _ => raise Inflate("reserved BTYPE")
    }
    if bfinal == 1 {
      break
    }
  }
  let end_pos = {
    let tmp = br
    tmp.align_to_byte()
    tmp.consumed()
  }
  if end_pos + 4 > zdata.length().reinterpret_as_uint() {
    raise Inflate("missing Adler32")
  }
  let adler_exp = uint32_from_be_bytes([
    zdata[end_pos.reinterpret_as_int()],
    zdata[end_pos.reinterpret_as_int() + 1],
    zdata[end_pos.reinterpret_as_int() + 2],
    zdata[end_pos.reinterpret_as_int() + 3],
  ])
  let adler_act = adler32(out)
  if adler_exp != adler_act {
    raise ZlibAdlerMismatch
  }
  (out, end_pos + 4)
}

///|
pub fn uint16_from_le_bytes(bytes : Array[Byte]) -> UInt16 {
  let lo = bytes[0].to_uint16()
  let hi = bytes[1].to_uint16()
  lo | (hi << 8)
}

///|
pub fn uint32_from_be_bytes(bytes : Array[Byte]) -> UInt {
  let b0 : UInt = bytes[0].to_uint()
  let b1 : UInt = bytes[1].to_uint()
  let b2 : UInt = bytes[2].to_uint()
  let b3 : UInt = bytes[3].to_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
pub fn extend_from_slice(
  src : Array[Byte],
  start : Int,
  end : Int,
) -> Array[Byte] {
  let out : Array[Byte] = Array::new()
  for i in start..<end {
    out.push(src[i])
  }
  out
}

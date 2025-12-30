///|
/// Internal numeric helpers.

pub fn clamp_u8(v : Int) -> Byte {
  if v < 0 {
    0
  } else if v > 255 {
    255
  } else {
    v.to_byte()
  }
}

fn round_to_int(v : Double) -> Int {
  if v >= 0.0 {
    (v + 0.5).to_int()
  } else {
    (v - 0.5).to_int()
  }
}

pub fn clamp_u8_f(v : Double) -> Byte {
  clamp_u8(round_to_int(v))
}



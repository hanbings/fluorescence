///|
test "crop_basic" {
  let p00 = RgbaColor::{ r: 10, g: 20, b: 30, a: 255 }
  let p10 = RgbaColor::{ r: 40, g: 50, b: 60, a: 255 }
  let p01 = RgbaColor::{ r: 70, g: 80, b: 90, a: 255 }
  let p11 = RgbaColor::{ r: 100, g: 110, b: 120, a: 255 }
  let pixels : Array[RgbaColor] = [p00, p10, p01, p11]
  let img = Image::{ pixels, width: 2, heigth: 2 }

  // In-bounds 1x1 crop at (0, 0).
  let c00 = img.crop(0, 0, 1, 1)
  assert_eq(c00.width, 1)
  assert_eq(c00.heigth, 1)
  assert_eq(c00.pixels.length(), 1)
  assert_eq(c00.pixels[0], p00)

  // Crop that extends outside image bounds should be clamped to full image.
  let full = img.crop(-1, -1, 10, 10)
  assert_eq(full.width, 2)
  assert_eq(full.heigth, 2)
  assert_eq(full.pixels.length(), 4)
  assert_eq(full.pixels[0], p00)
  assert_eq(full.pixels[1], p10)
  assert_eq(full.pixels[2], p01)
  assert_eq(full.pixels[3], p11)
}

///|
test "flip_h_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b], width: 2, heigth: 1 }
  let out = img.flip_h()
  assert_eq(out.width, 2)
  assert_eq(out.heigth, 1)
  assert_eq(out.pixels, [b, a])
}

///|
test "flip_v_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b], width: 1, heigth: 2 }
  let out = img.flip_v()
  assert_eq(out.width, 1)
  assert_eq(out.heigth, 2)
  assert_eq(out.pixels, [b, a])
}

///|
test "rotate90_cw_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let c = RgbaColor::{ r: 3, g: 0, b: 0, a: 255 }
  let d = RgbaColor::{ r: 4, g: 0, b: 0, a: 255 }
  let e = RgbaColor::{ r: 5, g: 0, b: 0, a: 255 }
  let f = RgbaColor::{ r: 6, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b, c, d, e, f], width: 2, heigth: 3 }
  let out = img.rotate90_cw()
  assert_eq(out.width, 3)
  assert_eq(out.heigth, 2)
  assert_eq(out.pixels, [e, c, a, f, d, b])
}

///|
test "rotate90_ccw_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let c = RgbaColor::{ r: 3, g: 0, b: 0, a: 255 }
  let d = RgbaColor::{ r: 4, g: 0, b: 0, a: 255 }
  let e = RgbaColor::{ r: 5, g: 0, b: 0, a: 255 }
  let f = RgbaColor::{ r: 6, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b, c, d, e, f], width: 2, heigth: 3 }
  let out = img.rotate90_ccw()
  assert_eq(out.width, 3)
  assert_eq(out.heigth, 2)
  assert_eq(out.pixels, [b, d, f, a, c, e])
}

///|
test "rotate180_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let c = RgbaColor::{ r: 3, g: 0, b: 0, a: 255 }
  let d = RgbaColor::{ r: 4, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b, c, d], width: 2, heigth: 2 }
  let out = img.rotate180()
  assert_eq(out.pixels, [d, c, b, a])
}

///|
test "crop_center_and_aspect" {
  let p0 = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let p1 = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let p2 = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let p3 = RgbaColor::{ r: 3, g: 0, b: 0, a: 255 }
  let q0 = RgbaColor::{ r: 10, g: 0, b: 0, a: 255 }
  let q1 = RgbaColor::{ r: 11, g: 0, b: 0, a: 255 }
  let q2 = RgbaColor::{ r: 12, g: 0, b: 0, a: 255 }
  let q3 = RgbaColor::{ r: 13, g: 0, b: 0, a: 255 }
  let img = Image::{
    pixels: [p0, p1, p2, p3, q0, q1, q2, q3],
    width: 4,
    heigth: 2,
  }
  let cc = img.crop_center(2, 2)
  assert_eq(cc.width, 2)
  assert_eq(cc.heigth, 2)
  assert_eq(cc.pixels, [p1, p2, q1, q2])
  let sq = img.crop_to_aspect(1, 1)
  assert_eq(sq.width, 2)
  assert_eq(sq.heigth, 2)
  assert_eq(sq.pixels, [p1, p2, q1, q2])
}

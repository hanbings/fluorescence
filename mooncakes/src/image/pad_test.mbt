///|
test "pad_constant" {
  let a = RgbaColor::{ r: 1, g: 2, b: 3, a: 4 }
  let img = Image::{ pixels: [a], width: 1, heigth: 1 }
  let c = RgbaColor::{ r: 9, g: 9, b: 9, a: 9 }
  let out = img.pad(1, 1, 1, 1, BorderMode::Constant(c))
  assert_eq(out.width, 3)
  assert_eq(out.heigth, 3)
  // center is original
  assert_eq(out.pixels[1 + 1 * 3], a)
  // corner is constant
  assert_eq(out.pixels[0], c)
}

///|
test "tile_basic" {
  let a = RgbaColor::{ r: 1, g: 0, b: 0, a: 255 }
  let b = RgbaColor::{ r: 2, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [a, b], width: 2, heigth: 1 }
  let out = img.tile(2, 2)
  assert_eq(out.width, 4)
  assert_eq(out.heigth, 2)
  // first row: a b a b
  assert_eq(out.pixels[0].r, 1)
  assert_eq(out.pixels[1].r, 2)
  assert_eq(out.pixels[2].r, 1)
  assert_eq(out.pixels[3].r, 2)
}

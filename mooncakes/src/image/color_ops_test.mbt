///|
test "threshold_gray_basic" {
  let p0 = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let p1 = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let img = Image::{ pixels: [p0, p1], width: 2, heigth: 1 }
  let out = img.threshold_gray(128)
  assert_eq(out.pixels[0].r, 0)
  assert_eq(out.pixels[1].r, 255)
}

///|
test "contrast_identity_factor1" {
  let p = RgbaColor::{ r: 10, g: 20, b: 30, a: 40 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let out = img.contrast(1.0)
  assert_eq(out, img)
}

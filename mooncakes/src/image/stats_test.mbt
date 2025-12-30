///|
test "histogram_rgba_counts" {
  let p0 = RgbaColor::{ r: 1, g: 2, b: 3, a: 4 }
  let p1 = RgbaColor::{ r: 1, g: 2, b: 9, a: 4 }
  let img = Image::{ pixels: [p0, p1], width: 2, heigth: 1 }
  let h = img.histogram_rgba()
  assert_eq(h.r[1], 2)
  assert_eq(h.g[2], 2)
  assert_eq(h.b[3], 1)
  assert_eq(h.b[9], 1)
  assert_eq(h.a[4], 2)
}

///|
test "psnr_identical_is_high" {
  let p = RgbaColor::{ r: 1, g: 2, b: 3, a: 4 }
  let a = Image::{ pixels: [p], width: 1, heigth: 1 }
  let b = Image::{ pixels: [p], width: 1, heigth: 1 }
  match psnr(a, b) {
    Some(v) => assert_true(v > 100.0)
    None => assert_true(false)
  }
}

///|
test "resize_upscale_nearest" {
  let red = RgbaColor::{ r: 255, g: 0, b: 0, a: 255 }
  let pixels : Array[RgbaColor] = [red]
  let img = Image::{ pixels, width: 1, heigth: 1 }
  let up = img.resize(2, 2)
  assert_eq(up.width, 2)
  assert_eq(up.heigth, 2)
  assert_eq(up.pixels.length(), 4)
  assert_eq(up.pixels[0], red)
  assert_eq(up.pixels[1], red)
  assert_eq(up.pixels[2], red)
  assert_eq(up.pixels[3], red)
}

///|
test "resize_downscale_nearest" {
  let p00 = RgbaColor::{ r: 10, g: 20, b: 30, a: 255 }
  let p10 = RgbaColor::{ r: 40, g: 50, b: 60, a: 255 }
  let p01 = RgbaColor::{ r: 70, g: 80, b: 90, a: 255 }
  let p11 = RgbaColor::{ r: 100, g: 110, b: 120, a: 255 }
  let pixels : Array[RgbaColor] = [p00, p10, p01, p11]
  let img = Image::{ pixels, width: 2, heigth: 2 }
  let down = img.resize(1, 1)
  assert_eq(down.width, 1)
  assert_eq(down.heigth, 1)
  assert_eq(down.pixels.length(), 1)
  assert_eq(down.pixels[0], p00)
}

///|
test "resize_bilinear_1x1_replicates" {
  let p = RgbaColor::{ r: 10, g: 20, b: 30, a: 40 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let up = img.resize_bilinear(3, 2)
  assert_eq(up.width, 3)
  assert_eq(up.heigth, 2)
  for q in up.pixels {
    assert_eq(q, p)
  }
}

///|
test "resize_bilinear_linear_gradient" {
  let left = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let right = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let img = Image::{ pixels: [left, right], width: 2, heigth: 1 }
  let out = img.resize_bilinear(3, 1)
  assert_eq(out.pixels[0].r, 0)
  assert_eq(out.pixels[2].r, 255)
  assert_eq(out.pixels[1].r, 128)
}

///|
test "to_grayscale_basic" {
  let black = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let white = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [black, white]
  let img = Image::{ pixels, width: 2, heigth: 1 }
  let gray_img = img.to_grayscale()
  assert_eq(gray_img.width, 2)
  assert_eq(gray_img.heigth, 1)
  assert_eq(gray_img.pixels.length(), 2)
  assert_eq(gray_img.pixels[0], RgbaColor::{ r: 0, g: 0, b: 0, a: 255 })
  assert_eq(gray_img.pixels[1], RgbaColor::{ r: 255, g: 255, b: 255, a: 255 })
}

///|
test "get_pixel_bounds" {
  let p = RgbaColor::{ r: 1, g: 2, b: 3, a: 4 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  assert_eq(img.get_pixel(0, 0), Some(p))
  assert_eq(img.get_pixel(-1, 0), None)
  assert_eq(img.get_pixel(0, -1), None)
  assert_eq(img.get_pixel(1, 0), None)
  assert_eq(img.get_pixel(0, 1), None)
}

///|
test "map_pixels_xy_coordinates" {
  let base = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let img = Image::{ pixels: [base, base, base, base], width: 2, heigth: 2 }
  let out = img.map_pixels_xy(fn(x, y, p) {
    let v = x + 10 * y
    RgbaColor::{ r: v.to_byte(), g: p.g, b: p.b, a: p.a }
  })
  assert_eq(out.pixels[0].r, 0)
  assert_eq(out.pixels[1].r, 1)
  assert_eq(out.pixels[2].r, 10)
  assert_eq(out.pixels[3].r, 11)
}

///|
test "invert_rgb_and_brightness" {
  let p = RgbaColor::{ r: 10, g: 20, b: 30, a: 40 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let inv = img.invert_rgb()
  assert_eq(inv.pixels[0], RgbaColor::{ r: 245, g: 235, b: 225, a: 40 })

  let bright = img.adjust_brightness(300)
  assert_eq(bright.pixels[0], RgbaColor::{ r: 255, g: 255, b: 255, a: 40 })

  let dark = img.adjust_brightness(-300)
  assert_eq(dark.pixels[0], RgbaColor::{ r: 0, g: 0, b: 0, a: 40 })
}



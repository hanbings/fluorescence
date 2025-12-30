///|
test "to_gray_buffer_range" {
  let black = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let white = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [black, white]
  let img = Image::{ pixels, width: 2, heigth: 1 }
  let buf = img.to_gray_buffer()
  assert_eq(buf.length(), 2)
  assert_eq(buf[0], 0.0)
  let diff = if buf[1] > 1.0 { buf[1] - 1.0 } else { 1.0 - buf[1] }
  let ok = diff < 0.000000001
  assert_true(ok)
}

///|
test "spectrum_to_image_basic" {
  let data : Array[Double] = [0.0, 1.0]
  let spec = ImageSpectrum::{ width: 1, heigth: 2, data }
  let img = spec.to_image()
  assert_eq(img.width, 1)
  assert_eq(img.heigth, 2)
  assert_eq(img.pixels.length(), 2)
  assert_eq(img.pixels[0], RgbaColor::{ r: 0, g: 0, b: 0, a: 255 })
  assert_eq(img.pixels[1], RgbaColor::{ r: 255, g: 255, b: 255, a: 255 })
}



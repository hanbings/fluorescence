///|
test "convolve3x3_identity" {
  let a = RgbaColor::{ r: 1, g: 2, b: 3, a: 255 }
  let b = RgbaColor::{ r: 4, g: 5, b: 6, a: 255 }
  let c = RgbaColor::{ r: 7, g: 8, b: 9, a: 255 }
  let d = RgbaColor::{ r: 10, g: 11, b: 12, a: 255 }
  let img = Image::{ pixels: [a, b, c, d], width: 2, heigth: 2 }
  let k : Array[Double] = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
  let out = img.convolve3x3(k, BorderMode::Clamp)
  assert_eq(out, img)
}

///|
test "box_blur3_center_impulse" {
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let out = img.box_blur3(BorderMode::Clamp)
  assert_eq(out.pixels[4], RgbaColor::{ r: 28, g: 28, b: 28, a: 255 })
}

///|
test "gaussian_blur3_center_impulse" {
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let out = img.gaussian_blur3(BorderMode::Clamp)
  assert_eq(out.pixels[4], RgbaColor::{ r: 64, g: 64, b: 64, a: 255 })
}

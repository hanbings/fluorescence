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

///|
test "convolve5x5_identity" {
  let a = RgbaColor::{ r: 1, g: 2, b: 3, a: 255 }
  let b = RgbaColor::{ r: 4, g: 5, b: 6, a: 255 }
  let c = RgbaColor::{ r: 7, g: 8, b: 9, a: 255 }
  let d = RgbaColor::{ r: 10, g: 11, b: 12, a: 255 }
  let img = Image::{ pixels: [a, b, c, d], width: 2, heigth: 2 }
  // 5x5 identity: center coefficient = 1.
  let k : Array[Double] = [
    0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0,
  ]
  let out = img.convolve5x5(k, BorderMode::Clamp)
  assert_eq(out, img)
}

///|
test "separable_gaussian_matches_gaussian_blur3_center" {
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let k1 : Array[Double] = [1.0, 2.0, 1.0]
  let out = img.separable_convolve_ex(k1, k1, 1.0 / 16.0, 0.0, BorderMode::Clamp)
  assert_eq(out.pixels[4], RgbaColor::{ r: 64, g: 64, b: 64, a: 255 })
}

///|
test "median_filter_removes_spike" {
  // 3x3 with a single white spike in the center should become black after median.
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let out = img.median_filter(1, BorderMode::Clamp)
  assert_eq(out.pixels[4], z)
}

///|
test "box_blur_radius1_matches_box_blur3_center" {
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let out = img.box_blur(1, BorderMode::Clamp)
  assert_eq(out.pixels[4], RgbaColor::{ r: 28, g: 28, b: 28, a: 255 })
}

///|
test "gaussian_blur_radius1_sigma_matches_gaussian_blur3_center" {
  // Choose sigma so that exp(-1/(2*sigma^2)) ~= 0.5 -> kernel ~ [1,2,1].
  let sigma = 0.8493218
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [z, z, z, z, w, z, z, z, z]
  let img = Image::{ pixels, width: 3, heigth: 3 }
  let out = img.gaussian_blur(1, sigma, BorderMode::Clamp)
  // allow tiny numeric drift around 64.
  let v = out.pixels[4].r.to_int()
  assert_true(v >= 63 && v <= 65)
}

///|
test "motion_blur_preserves_constant" {
  let p = RgbaColor::{ r: 50, g: 60, b: 70, a: 80 }
  let img = Image::{ pixels: Array::make(25, p), width: 5, heigth: 5 }
  let out = img.motion_blur(7, @math.PI / 4.0, BorderMode::Clamp)
  assert_eq(out, img)
}

///|
test "laplacian_zero_on_constant" {
  let p = RgbaColor::{ r: 10, g: 10, b: 10, a: 255 }
  let img = Image::{ pixels: Array::make(9, p), width: 3, heigth: 3 }
  let out = img.laplacian(BorderMode::Clamp)
  // All outputs should be 0 on a constant field.
  for q in out.pixels {
    assert_eq(q.r, 0)
    assert_eq(q.g, 0)
    assert_eq(q.b, 0)
  }
}

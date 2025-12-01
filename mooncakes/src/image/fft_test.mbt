///|
/// Basic correctness tests for FFT/DFT utilities in this package.

///|
/// 1D FFT + IFFT round-trip on a small complex vector.
test "image::fft1d_roundtrip" {
  let input : Array[Complex] = [
    Complex::{ re: 1.0, im: 0.0 },
    Complex::{ re: 2.0, im: -1.0 },
    Complex::{ re: -0.5, im: 0.25 },
    Complex::{ re: 0.0, im: 1.0 },
  ]
  let freq = fft1d(input)
  let restored = ifft1d(freq)
  let n = input.length()
  let mut max_err = 0.0
  for i in 0..<n {
    let dx = restored[i].re - input[i].re
    let dy = restored[i].im - input[i].im
    let err = (dx * dx + dy * dy).sqrt()
    if err > max_err {
      max_err = err
    }
  }

  // Allow a small numerical tolerance.
  let ok = max_err < 0.000001
  assert_true(ok)
}

///|
/// 2D FFT + IFFT round-trip on a tiny 2x2 complex "image".
test "image::fft2d_roundtrip" {
  let width = 2
  let heigth = 2
  let input : Array[Complex] = [
    Complex::{ re: 1.0, im: 0.0 },
    Complex::{ re: 0.0, im: 1.0 },
    Complex::{ re: -1.0, im: 0.5 },
    Complex::{ re: 0.5, im: -0.5 },
  ]
  let freq = fft2d(width, heigth, input)
  let restored = ifft2d(width, heigth, freq)
  let n = input.length()
  let mut max_err = 0.0
  for i in 0..<n {
    let dx = restored[i].re - input[i].re
    let dy = restored[i].im - input[i].im
    let err = (dx * dx + dy * dy).sqrt()
    if err > max_err {
      max_err = err
    }
  }
  let ok = max_err < 0.000001
  assert_true(ok)
}

///|
/// Integration test: `Image::fft_gray` produces a spectrum with expected shape
/// and normalized data range in [0.0, 1.0].
test "image::fft_gray_basic" {
  // 2x2 RGBA image with some variation.
  let pixels : Array[RgbaColor] = [
    RgbaColor::{ r: 0, g: 0, b: 0, a: 255 },
    RgbaColor::{ r: 255, g: 255, b: 255, a: 255 },
    RgbaColor::{ r: 255, g: 0, b: 0, a: 255 },
    RgbaColor::{ r: 0, g: 255, b: 0, a: 255 },
  ]
  let img = Image::{ pixels, width: 2, heigth: 2 }
  let spec = img.fft_gray()

  // Shape checks.
  assert_eq(spec.width, 2)
  assert_eq(spec.heigth, 2)
  assert_eq(spec.data.length(), 4)

  // Range checks: all values should be within [0.0, 1.0] (allowing a tiny epsilon).
  let mut min_v = 1.0
  let mut max_v = 0.0
  for v in spec.data {
    if v < min_v {
      min_v = v
    }
    if v > max_v {
      max_v = v
    }
  }
  let ok_min = min_v >= 0.0
  let ok_max = max_v <= 1.0 + 0.000000001
  assert_true(ok_min)
  assert_true(ok_max)
}

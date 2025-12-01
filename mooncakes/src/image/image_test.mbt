///|
/// Tests for core image operations: crop, grayscale, resize, and spectrum helpers.

///|
/// Basic crop behavior on a 2x2 image, including in-bounds and clamped crop.
test "image::crop_basic" {
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
/// Grayscale conversion of a few simple pixels.
test "image::to_grayscale_basic" {
  let black = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let white = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [black, white]
  let img = Image::{ pixels, width: 2, heigth: 1 }
  let gray_img = img.to_grayscale()
  assert_eq(gray_img.width, 2)
  assert_eq(gray_img.heigth, 1)
  assert_eq(gray_img.pixels.length(), 2)

  // Black stays black.
  assert_eq(gray_img.pixels[0], RgbaColor::{ r: 0, g: 0, b: 0, a: 255 })
  // White stays white (average of 255,255,255 is 255).
  assert_eq(gray_img.pixels[1], RgbaColor::{ r: 255, g: 255, b: 255, a: 255 })
}

///|
/// `to_gray_buffer` produces values in [0.0, 1.0] with expected extremes.
test "image::to_gray_buffer_range" {
  let black = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let white = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let pixels : Array[RgbaColor] = [black, white]
  let img = Image::{ pixels, width: 2, heigth: 1 }
  let buf = img.to_gray_buffer()
  assert_eq(buf.length(), 2)

  // Exact extremes.
  assert_eq(buf[0], 0.0)
  // White should map very close to 1.0 (within tiny tolerance).
  let diff = if buf[1] > 1.0 { buf[1] - 1.0 } else { 1.0 - buf[1] }
  let ok = diff < 0.000000001
  assert_true(ok)
}

///|
/// `ImageSpectrum::to_image` maps 0.0 and 1.0 to black and white pixels.
test "image::spectrum_to_image_basic" {
  let data : Array[Double] = [0.0, 1.0]
  let spec = ImageSpectrum::{ width: 1, heigth: 2, data }
  let img = spec.to_image()
  assert_eq(img.width, 1)
  assert_eq(img.heigth, 2)
  assert_eq(img.pixels.length(), 2)
  assert_eq(img.pixels[0], RgbaColor::{ r: 0, g: 0, b: 0, a: 255 })
  assert_eq(img.pixels[1], RgbaColor::{ r: 255, g: 255, b: 255, a: 255 })
}

///|
/// Nearest-neighbor resize: 1x1 -> 2x2 replicates the single source pixel.
test "image::resize_upscale_nearest" {
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
/// Nearest-neighbor resize: 2x2 -> 1x1 picks the top-left pixel.
test "image::resize_downscale_nearest" {
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

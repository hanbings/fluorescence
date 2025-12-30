///|
test "resize_area_downscale_average" {
  // 2x2 -> 1x1 should average the 4 pixels (area resampling).
  // Use one white pixel and 3 black pixels => avg = 63.75 -> round = 64
  let z = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let w = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let img = Image::{ pixels: [z, z, z, w], width: 2, heigth: 2 }
  let out = img.resize_area(1, 1)
  assert_eq(out.width, 1)
  assert_eq(out.heigth, 1)
  assert_eq(out.pixels[0].r, 64)
  assert_eq(out.pixels[0].g, 64)
  assert_eq(out.pixels[0].b, 64)
}

///|
test "resize_lanczos3_1x1_replicates" {
  let p = RgbaColor::{ r: 10, g: 20, b: 30, a: 40 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let out = img.resize_lanczos3(5, 3)
  assert_eq(out.width, 5)
  assert_eq(out.heigth, 3)
  for q in out.pixels {
    assert_eq(q, p)
  }
}

///|
test "resize_lanczos3_gradient_midpoint_reasonable" {
  // 2x1 gradient [0,255] -> 3x1, endpoints should stay endpoints.
  // Middle should be around 128 (allow some ringing; just bound it).
  let left = RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
  let right = RgbaColor::{ r: 255, g: 255, b: 255, a: 255 }
  let img = Image::{ pixels: [left, right], width: 2, heigth: 1 }
  let out = img.resize_lanczos3(3, 1)
  assert_eq(out.pixels[0].r, 0)
  assert_eq(out.pixels[2].r, 255)
  let mid = out.pixels[1].r.to_int()
  assert_true(mid >= 80)
  assert_true(mid <= 175)
}

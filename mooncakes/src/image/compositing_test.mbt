///|
test "opacity_scales_alpha" {
  let p = RgbaColor::{ r: 10, g: 20, b: 30, a: 100 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let out = img.opacity(0.5)
  assert_eq(out.pixels[0].a, 50)
}

///|
test "replace_alpha_constant" {
  let p = RgbaColor::{ r: 1, g: 2, b: 3, a: 4 }
  let img = Image::{ pixels: [p], width: 1, heigth: 1 }
  let out = img.replace_alpha(200)
  assert_eq(out.pixels[0], RgbaColor::{ r: 1, g: 2, b: 3, a: 200 })
}

///|
test "blit_replace" {
  let dst = Image::{
    pixels: [RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }],
    width: 1,
    heigth: 1,
  }
  let src = Image::{
    pixels: [RgbaColor::{ r: 9, g: 8, b: 7, a: 6 }],
    width: 1,
    heigth: 1,
  }
  let out = dst.blit(src, 0, 0, BlendMode::Replace)
  assert_eq(out.pixels[0], RgbaColor::{ r: 9, g: 8, b: 7, a: 6 })
}

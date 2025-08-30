///|
fn a_bytes(n : Int) -> Array[Byte] {
  let array : Array[Byte] = Array::new()
  for index in 0..<n {
    array.push('a')
  }
  array
}

///|
test "scale_to_byte_depth1_test" {
  // 1bit: 0 -> 0, 1 -> 255
  assert_eq(scale_to_byte(0, 1), 0)
  assert_eq(scale_to_byte(1, 1), 255)
}

///|
test "scale_to_byte_depth2_test" {
  // 2bit: 0..3 → 0,85,170,255
  assert_eq(scale_to_byte(0, 2), 0)
  assert_eq(scale_to_byte(1, 2), 85)
  assert_eq(scale_to_byte(2, 2), 170)
  assert_eq(scale_to_byte(3, 2), 255)
}

///|
test "scale_to_byte_depth4_test" {
  // 4bit: 0..15 → 0..255
  assert_eq(scale_to_byte(0, 4), 0)
  assert_eq(scale_to_byte(1, 4), 17)
  assert_eq(scale_to_byte(7, 4), 119)
  assert_eq(scale_to_byte(8, 4), 136)
  assert_eq(scale_to_byte(15, 4), 255)
}

///|
test "scale_to_byte_depth8_test" {
  assert_eq(scale_to_byte(0x00, 8), 0)
  assert_eq(scale_to_byte(0xFF, 8), 255)
}

///|
test "scale_to_byte_depth16_test" {
  assert_eq(scale_to_byte(0x0000, 16), 0x00)
  assert_eq(scale_to_byte(0x00FF, 16), 0x00)
  assert_eq(scale_to_byte(0xFF00, 16), 0xFF)
  assert_eq(scale_to_byte(0x1234, 16), 0x12)
  assert_eq(scale_to_byte(0xFFFF, 16), 0xFF)
}

///|
test "normalize_trns_sample_depth16_passthrough_test" {
  assert_eq(normalize_trns_sample(0x0000, 16), 0x0000)
  assert_eq(normalize_trns_sample(0xABCD, 16), 0xABCD)
  assert_eq(normalize_trns_sample(0xFFFF, 16), 0xFFFF)
}

///|
test "normalize_trns_sample_depth8_test" {
  assert_eq(normalize_trns_sample(0x0000, 8), 0x00)
  assert_eq(normalize_trns_sample(0xFF00, 8), 0xFF)
  assert_eq(normalize_trns_sample(0x8000, 8), 0x80)
  assert_eq(normalize_trns_sample(0xFFFF, 8), 0xFF)
}

///|
test "normalize_trns_sample_depth4_test" {
  assert_eq(normalize_trns_sample(0x0000, 4), 0x0)
  assert_eq(normalize_trns_sample(0x1000, 4), 0x1)
  assert_eq(normalize_trns_sample(0x8000, 4), 0x8)
  assert_eq(normalize_trns_sample(0xFFFF, 4), 0xF)
}

///|
test "normalize_trns_sample_depth2_test" {
  assert_eq(normalize_trns_sample(0x0000, 2), 0)
  assert_eq(normalize_trns_sample(0x4000, 2), 1)
  assert_eq(normalize_trns_sample(0x8000, 2), 2)
  assert_eq(normalize_trns_sample(0xC000, 2), 3)
  assert_eq(normalize_trns_sample(0xFFFF, 2), 3)
}

///|
test "normalize_trns_sample_depth1_test" {
  assert_eq(normalize_trns_sample(0x0000, 1), 0)
  assert_eq(normalize_trns_sample(0x8000, 1), 1)
  assert_eq(normalize_trns_sample(0xFFFF, 1), 1)
}

///|
test "normalize_trns_sample_depth16_passthrough_test" {
  assert_eq(normalize_trns_sample(0x0000, 16), 0x0000)
  assert_eq(normalize_trns_sample(0xABCD, 16), 0xABCD)
  assert_eq(normalize_trns_sample(0xFFFF, 16), 0xFFFF)
}

// Helper: build minimal Ihdr

///|
fn mk_ihdr(bit_depth : Byte, ct : ColorType) -> Ihdr {
  Ihdr::{
    width: 1,
    height: 1,
    bit_depth,
    color_type: ct,
    compression_method: 0,
    filter_method: 0,
    interlace_method: 0,
  }
}

// Helper: build minimal Png with optional Trns

///|
fn mk_png_base(bit_depth : Byte, ct : ColorType, trns : Trns?) -> Png {
  Png::{
    ihdr: mk_ihdr(bit_depth, ct),
    palette: None,
    palette_alpha: None,
    trns,
    bkgd_rgb16: None,
    gamma: None,
    srgb_intent: None,
    chrm: None,
    phys: None,
    text: [],
    iccp: None,
    idat: [],
  }
}

///|
fn mk_png_no_trns(bit_depth : Byte, ct : ColorType) -> Png {
  mk_png_base(bit_depth, ct, None)
}

///|
fn mk_png_gray_trns(bit_depth : Byte, sample : UInt16) -> Png {
  mk_png_base(
    bit_depth,
    ColorType::Grayscale,
    Some(Trns::Gray(Gray::{ sample, bit_depth })),
  )
}

///|
fn mk_png_rgb_trns(bit_depth : Byte, r : UInt16, g : UInt16, b : UInt16) -> Png {
  mk_png_base(
    bit_depth,
    ColorType::Rgb,
    Some(Trns::Rgb(Rgb::{ r, g, b, bit_depth })),
  )
}

///|
/// Test: Grayscale without tRNS should be opaque
test "apply_trns_gray_no_trns_opaque_test" {
  let png = mk_png_no_trns(8, ColorType::Grayscale)
  let (g, a) = apply_trns_gray(png, 200)
  assert_eq(g, scale_to_byte(200, 8))
  assert_eq(a, 255)
}

///|
/// Test: Grayscale with tRNS, matching sample → transparent
test "apply_trns_gray_match_transparent_test" {
  let bit = 16
  let sample : UInt16 = 0x1234
  let png = mk_png_gray_trns(bit.to_byte(), sample)
  let (g, a) = apply_trns_gray(png, sample)
  assert_eq(g, scale_to_byte(sample, bit.to_byte()))
  assert_eq(a, 0)
}

///|
/// Test: Grayscale with tRNS, not matching → opaque
test "apply_trns_gray_not_match_opaque_test" {
  let bit = 16
  let png = mk_png_gray_trns(bit.to_byte(), 0x00FF)
  let (g, a) = apply_trns_gray(png, 0x00FE)
  assert_eq(g, scale_to_byte(0x00FE, bit.to_byte()))
  assert_eq(a, 255)
}

///|
/// Test: Grayscale 8-bit scaling and alpha
test "apply_trns_gray_8bit_scaling_and_alpha_test" {
  let bit = 8
  let sample : UInt16 = 128
  let png_eq = mk_png_gray_trns(bit.to_byte(), sample)
  let (g1, a1) = apply_trns_gray(png_eq, 128)
  assert_eq(g1, 128)
  assert_eq(a1, 0)
  let png_ne = mk_png_gray_trns(bit.to_byte(), sample)
  let (g2, a2) = apply_trns_gray(png_ne, 200)
  assert_eq(g2, 200)
  assert_eq(a2, 255)
}

///|
/// Test: RGB without tRNS should be opaque
test "apply_trns_rgb_no_trns_opaque_test" {
  let png = mk_png_no_trns(8, ColorType::Rgb)
  let (r8, g8, b8, a) = apply_trns_rgb(png, 10, 20, 30)
  assert_eq(r8, scale_to_byte(10, 8))
  assert_eq(g8, scale_to_byte(20, 8))
  assert_eq(b8, scale_to_byte(30, 8))
  assert_eq(a, 255)
}

///|
/// Test: RGB with tRNS fully matching → transparent
test "apply_trns_rgb_match_transparent_test" {
  let bit = 16
  let rr : UInt16 = 0xABCD
  let gg : UInt16 = 0x00FF
  let bb : UInt16 = 0x4242
  let png = mk_png_rgb_trns(bit.to_byte(), rr, gg, bb)
  let (r8, g8, b8, a) = apply_trns_rgb(png, rr, gg, bb)
  assert_eq(r8, scale_to_byte(rr, bit.to_byte()))
  assert_eq(g8, scale_to_byte(gg, bit.to_byte()))
  assert_eq(b8, scale_to_byte(bb, bit.to_byte()))
  assert_eq(a, 0)
}

///|
/// Test: RGB with one channel different → opaque
test "apply_trns_rgb_one_channel_diff_opaque_test" {
  let bit = 16
  let rr : UInt16 = 0xABCD
  let gg : UInt16 = 0x00FF
  let bb : UInt16 = 0x4242
  let png = mk_png_rgb_trns(bit.to_byte(), rr, gg, bb)
  let (r8, g8, b8, a) = apply_trns_rgb(png, 0xABCE, gg, bb)
  assert_eq(r8, scale_to_byte(0xABCE, bit.to_byte()))
  assert_eq(g8, scale_to_byte(gg, bit.to_byte()))
  assert_eq(b8, scale_to_byte(bb, bit.to_byte()))
  assert_eq(a, 255)
}

///|
/// Test: RGB 8-bit scaling and alpha
test "apply_trns_rgb_8bit_scaling_and_alpha_test" {
  let bit = 8
  let rr : UInt16 = 10
  let gg : UInt16 = 128
  let bb : UInt16 = 250
  let png_eq = mk_png_rgb_trns(bit.to_byte(), rr, gg, bb)
  let (r1, g1, b1, a1) = apply_trns_rgb(png_eq, rr, gg, bb)
  assert_eq(r1, 10)
  assert_eq(g1, 128)
  assert_eq(b1, 250)
  assert_eq(a1, 0)
  let png_ne = mk_png_rgb_trns(bit.to_byte(), rr, gg, bb)
  let (r2, g2, b2, a2) = apply_trns_rgb(png_ne, rr, gg, 251)
  assert_eq(r2, 10)
  assert_eq(g2, 128)
  assert_eq(b2, 251)
  assert_eq(a2, 255)
}

///|
/// Test: alpha = 255 → fully opaque foreground
test "over_full_alpha" {
  // Foreground fully covers background
  assert_eq(over(100, 255, 200), 100)
  assert_eq(over(0, 255, 255), 0)
  assert_eq(over(255, 255, 0), 255)
}

///|
/// Test: alpha = 0 → fully transparent (only background visible)
test "over_zero_alpha" {
  // Foreground ignored, result is background
  assert_eq(over(100, 0, 200), 200)
  assert_eq(over(50, 0, 80), 80)
}

///|
/// Test: alpha = 128 → 50% blend (approximate midpoint)
test "over_half_alpha" {
  // Formula: (c*128 + bg*127) / 255
  // Example: (0*128 + 255*127)/255 ≈ 127
  assert_eq(over(0, 128, 255), 127)
  // Example: (255*128 + 0*127)/255 ≈ 128
  assert_eq(over(255, 128, 0), 128)
}

///|
/// Test: general alpha values
test "over_general_alpha" {
  // Example: c=200, a=64, bg=100
  // (200*64 + 100*191)/255 = (12800 + 19100)/255 ≈ 125
  assert_eq(over(200, 64, 100), 125)

  // Example: c=50, a=192, bg=200
  // (50*192 + 200*63)/255 = (9600 + 12600)/255 ≈ 87
  assert_eq(over(50, 192, 200), 87)
}

///|
test "split_at_nul_ok_basic_test" {
  let buf : Array[Byte] = [
    'k', 'e', 'y', 'w', 'o', 'r', 'd', 0, 'v', 'a', 'l', 'u', 'e',
  ]
  let (k, v) = split_at_nul(buf)
  assert_eq(k, "keyword")
  assert_eq(v, "value")
}

///|
test "split_at_nul_ok_empty_value_test" {
  let buf : Array[Byte] = ['k', 'e', 'y', 'w', 'o', 'r', 'd', 0]
  let (k, v) = split_at_nul(buf)
  assert_eq(k, "keyword")
  assert_eq(v, "")
}

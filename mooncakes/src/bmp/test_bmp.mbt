///|
test "test_bmp_image" {
  let data : Array[Byte] = [
    // BITMAPFILEHEADER
    // Signature 'BM'
    0x42, 0x4D,
    // File size = 62 bytes
     0x3E, 0x00, 0x00, 0x00,
    // Reserved1
     0x00, 0x00,
    // Reserved2
     0x00, 0x00,
    // Pixel data offset (54)
     0x36, 0x00, 0x00, 0x00,

    // BITMAPINFOHEADER (40 bytes)
    // Header size = 40
     0x28, 0x00, 0x00, 0x00,
    // Width = 2
     0x02, 0x00, 0x00, 0x00,
    // Height = 2 (bottom-up)
     0x02, 0x00, 0x00, 0x00,
    // Planes = 1
     0x01, 0x00,
    // BitCount = 24
     0x18, 0x00,
    // Compression = BI_RGB
     0x00, 0x00, 0x00, 0x00,
    // Image size (8 bytes including padding)
     0x08, 0x00, 0x00, 0x00,
    // X pixels per meter (2835 ~ 72 DPI)
     0x13, 0x0B, 0x00, 0x00,
    // Y pixels per meter
     0x13, 0x0B, 0x00, 0x00,
    // Colors used
     0x00, 0x00, 0x00, 0x00,
    // Important colors
     0x00, 0x00, 0x00, 0x00,

    // Pixel data (bottom-up, rows padded to 4 bytes)
    // Row 0 (bottom row): Blue, Green
    // Pixel(0,0) = Blue (B,G,R)
     0xFF, 0x00, 0x00,
    // Pixel(1,0) = Green
     0x00, 0xFF, 0x00,
    // Padding to 4-byte boundary
     0x00, 0x00,

    // Row 1 (top row): Red, White
    // Pixel(0,1) = Red
     0x00, 0x00, 0xFF,
    // Pixel(1,1) = White
     0xFF, 0xFF, 0xFF,
    // Padding
     0x00, 0x00,
  ]

  //
  let bmp = parse_bmp(data)
  assert_eq(bmp.height, 2)
  assert_eq(bmp.width, 2)
}

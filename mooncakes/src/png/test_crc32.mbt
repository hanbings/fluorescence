///|
test "basic_crc32_table_test" {
  let table = crc32_table()

  // check that the crc32 table length is 256.
  assert_eq(table.length(), 256)

  // check some typical values.
  assert_eq(table[0], 0x00000000U)
  assert_eq(table[1], 0x77073096U)
  assert_eq(table[2], 0xee0e612cU)
  assert_eq(table[255], 0x2d02ef8dU)
}

///|
test "zero_crc32_test" {
  let b = []
  let res = crc32(b)
  assert_eq(res, 0)
}

///|
test "simple_crc32_test" {
  let b = [49U, 50U, 51U, 52U, 53U, 54U, 55U, 56U, 57U]
  let res = crc32(b)
  assert_eq(res, 0xcbf43926)
}

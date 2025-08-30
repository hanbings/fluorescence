///|
/// Test: read exactly len bytes in one shot
test "vec_reader_read_basic" {
  let reader = @ref.new(VecReader::{ data: [1, 2, 3, 4, 5, 6, 7, 8], pos: 0 })
  let out : Array[Byte] = [0, 0, 0, 0, 0, 0, 0, 0]
  let n1 = reader.val.vec_reader_read(@ref.new(out))
  assert_eq(n1, 8)
  assert_eq(out, [1, 2, 3, 4, 5, 6, 7, 8])

  // EOF now
  let n2 = reader.val.vec_reader_read(@ref.new(out))
  assert_eq(n2, 0)
}

///|
/// Test: multi-chunk reads
test "vec_reader_read_chunks" {
  let reader = @ref.new(VecReader::{ data: [10, 20, 30, 40, 50], pos: 0 })
  let buf : Array[Byte] = [0, 0, 0]
  let n1 = reader.val.vec_reader_read(@ref.new(buf))
  assert_eq(n1, 3)
  assert_eq(buf, [10, 20, 30])
  let n2 = reader.val.vec_reader_read(@ref.new(buf))
  assert_eq(n2, 2)
  assert_eq(buf[0], 40)
  assert_eq(buf[1], 50)
}

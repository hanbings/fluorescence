///|
test "fftshift_ifftshift_roundtrip" {
  let data : Array[Double] = [0.0, 1.0, 2.0, 3.0]
  let s = ImageSpectrum::{ width: 2, heigth: 2, data }
  let out = s.fftshift().ifftshift()
  assert_eq(out.data, data)
}

///|
test "log_magnitude_range" {
  let data : Array[Double] = [0.0, 1.0]
  let s = ImageSpectrum::{ width: 1, heigth: 2, data }
  let out = s.log_magnitude(10.0)
  assert_true(out.data[0] >= 0.0)
  assert_true(out.data[1] <= 1.0 + 0.000000001)
}

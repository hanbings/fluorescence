///|
/// Simple complex number type used for FFT/DFT operations.
pub(all) struct Complex {
  re : Double
  im : Double
} derive(Default, Show)

///|
/// Compute the 1D discrete Fourier transform (DFT) of a complex vector.
///
/// This is an O(n^2) implementation (not an optimized radix-2 FFT), but
/// it is numerically correct and works for any length `n`.
pub fn fft1d(input : Array[Complex]) -> Array[Complex] {
  let n = input.length()
  let output : Array[Complex] = Array::make(n, Complex::default())
  let n_d = n.to_double()
  for k in 0..<n {
    let mut sum_re = 0.0
    let mut sum_im = 0.0
    for t in 0..<n {
      let angle = -2.0 * @math.PI * k.to_double() * t.to_double() / n_d
      let c = @math.cos(angle)
      let s = @math.sin(angle)
      let x = input[t]
      // Multiply x by e^{-i * angle} = cos(angle) + i * sin(angle) with negative angle
      sum_re = sum_re + x.re * c - x.im * s
      sum_im = sum_im + x.re * s + x.im * c
    }
    output[k] = Complex::{ re: sum_re, im: sum_im }
  }
  output
}

///|
/// Compute the inverse 1D discrete Fourier transform (IDFT) of a complex vector.
///
/// This is the mathematical inverse of `fft1d`. It has the same O(n^2)
/// complexity and works for arbitrary lengths.
pub fn ifft1d(input : Array[Complex]) -> Array[Complex] {
  let n = input.length()
  let output : Array[Complex] = Array::make(n, Complex::default())
  let n_d = n.to_double()
  for k in 0..<n {
    let mut sum_re = 0.0
    let mut sum_im = 0.0
    for t in 0..<n {
      // Note the positive sign in the exponent for the inverse transform.
      let angle = 2.0 * @math.PI * k.to_double() * t.to_double() / n_d
      let c = @math.cos(angle)
      let s = @math.sin(angle)
      let x = input[t]
      // Multiply x by e^{i * angle} = cos(angle) + i * sin(angle)
      sum_re = sum_re + x.re * c - x.im * s
      sum_im = sum_im + x.re * s + x.im * c
    }

    // Normalize by N to complete the inverse transform.
    output[k] = Complex::{ re: sum_re / n_d, im: sum_im / n_d }
  }
  output
}

///|
/// Compute the 2D DFT of a `width x heigth` complex image.
///
/// The input is a flattened buffer of length `width * heigth` in row-major
/// order. The result has the same layout.
pub fn fft2d(
  width : Int,
  heigth : Int,
  input : Array[Complex],
) -> Array[Complex] {
  let n = width * heigth
  if input.length() != n {
    return Array::make(n, Complex::default())
  }

  // First pass: transform rows.
  let tmp : Array[Complex] = Array::make(n, Complex::default())
  for y in 0..<heigth {
    // Extract one row.
    let row : Array[Complex] = Array::make(width, Complex::default())
    for x in 0..<width {
      row[x] = input[x + y * width]
    }
    let row_fft = fft1d(row)

    // Store back row transform.
    for x in 0..<width {
      tmp[x + y * width] = row_fft[x]
    }
  }

  // Second pass: transform columns.
  let output : Array[Complex] = Array::make(n, Complex::default())
  for x in 0..<width {
    // Extract one column.
    let col : Array[Complex] = Array::make(heigth, Complex::default())
    for y in 0..<heigth {
      col[y] = tmp[x + y * width]
    }
    let col_fft = fft1d(col)

    // Store back column transform.
    for y in 0..<heigth {
      output[x + y * width] = col_fft[y]
    }
  }
  output
}

///|
/// Compute the inverse 2D DFT of a `width x heigth` complex image.
///
/// This is the mathematical inverse of `fft2d`. It applies `ifft1d`
/// along rows and then columns.
pub fn ifft2d(
  width : Int,
  heigth : Int,
  input : Array[Complex],
) -> Array[Complex] {
  let n = width * heigth
  if input.length() != n {
    return Array::make(n, Complex::default())
  }

  // First pass: inverse-transform rows.
  let tmp : Array[Complex] = Array::make(n, Complex::default())
  for y in 0..<heigth {
    let row : Array[Complex] = Array::make(width, Complex::default())
    for x in 0..<width {
      row[x] = input[x + y * width]
    }
    let row_ifft = ifft1d(row)
    for x in 0..<width {
      tmp[x + y * width] = row_ifft[x]
    }
  }

  // Second pass: inverse-transform columns.
  let output : Array[Complex] = Array::make(n, Complex::default())
  for x in 0..<width {
    let col : Array[Complex] = Array::make(heigth, Complex::default())
    for y in 0..<heigth {
      col[y] = tmp[x + y * width]
    }
    let col_ifft = ifft1d(col)
    for y in 0..<heigth {
      output[x + y * width] = col_ifft[y]
    }
  }
  output
}

///|
/// Compute a grayscale frequency spectrum of an `Image` using 2D DFT.
///
/// The image is first converted to a normalized grayscale buffer in [0.0, 1.0],
/// then lifted to complex numbers and transformed with `fft2d`. The resulting
/// complex coefficients are converted to magnitudes and normalized back to
/// [0.0, 1.0] for visualization.
pub fn Image::fft_gray(self : Image) -> ImageSpectrum {
  let buf = self.to_gray_buffer()
  let n = self.width * self.heigth

  // Lift grayscale buffer into complex input.
  let complex_in : Array[Complex] = (0)
    .until(n)
    .map(fn(idx) { Complex::{ re: buf[idx], im: 0.0 } })
    .collect()
  let complex_out = fft2d(self.width, self.heigth, complex_in)

  // Convert complex coefficients to magnitudes.
  let mags : Array[Double] = complex_out.map(fn(c) {
    (c.re * c.re + c.im * c.im).sqrt()
  })

  // Find maximum magnitude for normalization.
  let max_val = mags.fold(init=0.0, fn(acc : Double, v : Double) {
    if v > acc {
      v
    } else {
      acc
    }
  })
  let data : Array[Double] = if max_val <= 0.0 {
    mags
  } else {
    mags.map(fn(v) { v / max_val })
  }
  ImageSpectrum::{ width: self.width, heigth: self.heigth, data }
}

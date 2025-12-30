///|
/// Image utilities for the `hanbings/fluorescence/image` package.
///
/// This package is split across multiple files by responsibility:
/// - `types.mbt`: core data types (`RgbaColor`, `Image`, `ImageSpectrum`)
/// - `utils.mbt`: internal numeric helpers (clamping/rounding)
/// - `sampling.mbt`: border sampling helpers (`BorderMode`, `Image::sample`)
/// - `color.mbt`: color utilities (`RgbaColor::calc_dist`)
/// - `pixel_ops.mbt`: pixel-level helpers & basic color ops
/// - `geometry.mbt`: crop/flip/rotate/resize
/// - `filters.mbt`: convolution & filters
/// - `spectrum.mbt`: grayscale spectrum helpers

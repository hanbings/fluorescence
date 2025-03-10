use alloc::vec::Vec;

use crate::RgbaColor;

pub mod kmeans;

pub trait PrimanyColor {
    fn get_primary_colors(&self) -> Result<Vec<RgbaColor>, ()>;
}

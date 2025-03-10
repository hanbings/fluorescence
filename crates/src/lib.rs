#![no_std]

extern crate alloc;

use alloc::vec::Vec;

#[derive(Debug, Clone, Copy)]
pub struct RgbaColor {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8,
}

#[derive(Debug, Clone)]
pub struct Image {
    pub pixels: Vec<RgbaColor>,
    pub width: u32,
    pub heigth: u32,
}

pub mod color;

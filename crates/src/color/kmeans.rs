use alloc::vec;
use alloc::vec::Vec;
use rand::Rng;

use super::PrimanyColor;
use crate::{Image, RgbaColor};

pub struct Kmeans {
    image: Image,
    init_centroid: u64,
    iteration: u64,
    min_distance: f64,
}

impl Kmeans {
    pub fn new(image: Image, init_centroid: u64, iteration: u64, min_distance: f64) -> Self {
        Self {
            image,
            init_centroid,
            iteration,
            min_distance,
        }
    }
}

impl PrimanyColor for Kmeans {
    fn get_primary_colors(&self) -> Result<Vec<RgbaColor>, ()> {
        let mut rng = rand::rng();
        let mut centroid: Vec<RgbaColor> = (0..self.init_centroid)
            .map(|_| RgbaColor {
                r: rng.random_range(0..=255),
                g: rng.random_range(0..=255),
                b: rng.random_range(0..=255),
                a: rng.random_range(0..=255),
            })
            .collect();

        let mut center_cluster: Vec<Vec<RgbaColor>> = vec![vec![]; self.init_centroid as usize];
        let mut iteration = self.iteration;

        while iteration > 0 {
            iteration -= 1;

            center_cluster
                .iter_mut()
                .for_each(|cluster| cluster.clear());

            for pixel in &self.image.pixels {
                let closest_center_index = centroid
                    .iter()
                    .enumerate()
                    .map(|(i, center)| (i, calc_dist(center, pixel)))
                    .min_by(|(_, dist1), (_, dist2)| dist1.partial_cmp(dist2).unwrap())
                    .unwrap()
                    .0;

                center_cluster[closest_center_index].push(*pixel);
            }

            let new_centroid: Vec<RgbaColor> = center_cluster
                .iter()
                .map(|cluster| {
                    let (total_r, total_g, total_b, total_a, count) = cluster.iter().fold(
                        (0u32, 0u32, 0u32, 0u32, 0u32),
                        |(tr, tg, tb, ta, count), pixel| {
                            (
                                tr + pixel.r as u32,
                                tg + pixel.g as u32,
                                tb + pixel.b as u32,
                                ta + pixel.a as u32,
                                count + 1,
                            )
                        },
                    );

                    if count > 0 {
                        RgbaColor {
                            r: (total_r / count) as u8,
                            g: (total_g / count) as u8,
                            b: (total_b / count) as u8,
                            a: (total_a / count) as u8,
                        }
                    } else {
                        RgbaColor {
                            r: 0,
                            g: 0,
                            b: 0,
                            a: 255,
                        }
                    }
                })
                .collect();

            let mut is_settled = true;
            for (new_center, old_center) in new_centroid.iter().zip(&centroid) {
                if calc_dist(new_center, old_center) > self.min_distance {
                    is_settled = false;
                    break;
                }
            }

            if is_settled {
                break;
            }

            centroid = new_centroid;
        }

        Ok(centroid)
    }
}

fn calc_dist(color1: &RgbaColor, color2: &RgbaColor) -> f64 {
    let dr = (color1.r as i32 - color2.r as i32).pow(2);
    let dg = (color1.g as i32 - color2.g as i32).pow(2);
    let db = (color1.b as i32 - color2.b as i32).pow(2);
    let da = (color1.a as i32 - color2.a as i32).pow(2);
    ((dr + dg + db + da) as f64).sqrt()
}

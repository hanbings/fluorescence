use alloc::collections::btree_map::BTreeMap;
use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;
use alloc::{boxed::Box, vec};
use spin::Mutex;

use super::PrimanyColor;
use crate::{Image, RgbaColor};

pub struct Octree {
    image: Image,
    leaf_limit: u32,
    primary_color_count: usize,
}

impl Octree {
    pub fn new(image: Image, leaf_limit: u32, primary_color_count: usize) -> Self {
        Self {
            image,
            leaf_limit,
            primary_color_count,
        }
    }
}

impl PrimanyColor for Octree {
    fn get_primary_colors(&self) -> Result<Vec<RgbaColor>, ()> {
        let mut root = OctreeNode::new(0);

        for pixel in &self.image.pixels {
            root.add_color(pixel, 0);

            let count = LEAF_COUNT.lock();
            while *count > self.leaf_limit {
                OctreeNode::reduce_tree();
            }
        }

        let mut record = BTreeMap::new();
        root.colors_stats(&mut record);

        let mut result: Vec<_> = record
            .into_iter()
            .map(|(hex, count)| {
                let r = u8::from_str_radix(&hex[1..3], 16).unwrap();
                let g = u8::from_str_radix(&hex[3..5], 16).unwrap();
                let b = u8::from_str_radix(&hex[5..7], 16).unwrap();
                let a = u8::from_str_radix(&hex[7..9], 16).unwrap();
                (RgbaColor { r, g, b, a }, count)
            })
            .collect();

        result.sort_by(|a, b| b.1.cmp(&a.1));
        Ok(result
            .iter()
            .take(self.primary_color_count)
            .map(|(color, _)| *color)
            .collect())
    }
}

#[derive(Debug, Clone)]
struct OctreeNode {
    children: [Option<Box<OctreeNode>>; 16],
    is_leaf: bool,
    r: u32,
    g: u32,
    b: u32,
    a: u32,
    children_count: u32,
}

lazy_static::lazy_static! {
    static ref LEAF_COUNT: Mutex<u32> = Mutex::new(0);
    static ref TO_REDUCE: Mutex<Vec<Vec<OctreeNode>>> = Mutex::new(vec![vec![]; 8]);
}

impl OctreeNode {
    pub fn new(level: usize) -> Self {
        let is_leaf = level == 7;
        if is_leaf {
            let mut count = LEAF_COUNT.lock();
            *count += 1;
        }
        Self {
            children: Default::default(),
            is_leaf,
            r: 0,
            g: 0,
            b: 0,
            a: 0,
            children_count: 0,
        }
    }

    pub fn add_color(&mut self, color: &RgbaColor, level: usize) {
        if self.is_leaf {
            self.children_count += 1;
            self.r += color.r as u32;
            self.g += color.g as u32;
            self.b += color.b as u32;
            self.a += color.a as u32;
        } else {
            let r_bit = (color.r >> (7 - level)) & 1;
            let g_bit = (color.g >> (7 - level)) & 1;
            let b_bit = (color.b >> (7 - level)) & 1;
            let a_bit = (color.a >> (7 - level)) & 1;
            let index = (r_bit << 3) | (g_bit << 2) | (b_bit << 1) | a_bit;

            if self.children[index as usize].is_none() {
                self.children[index as usize] = Some(Box::new(OctreeNode::new(level + 1)));
            }
            self.children[index as usize]
                .as_mut()
                .unwrap()
                .add_color(color, level + 1);
        }
    }

    pub fn reduce_tree() {
        let mut level = 6;

        let mut to_reduce = TO_REDUCE.lock();
        while level > 0 && (*to_reduce[level]).is_empty() {
            if level == 0 {
                return;
            }
            level -= 1;
        }

        let node = (*to_reduce[level]).last_mut().unwrap();

        node.is_leaf = true;
        node.r = 0;
        node.g = 0;
        node.b = 0;
        node.a = 0;
        node.children_count = 0;

        let mut count = LEAF_COUNT.lock();

        for child in node.children.iter_mut() {
            if let Some(child_node) = child.take() {
                node.r += child_node.r;
                node.g += child_node.g;
                node.b += child_node.b;
                node.a += child_node.a;
                node.children_count += child_node.children_count;
                *count -= 1;
            }
        }

        *count += 1;
    }

    pub fn colors_stats(&self, record: &mut BTreeMap<String, u32>) {
        if self.is_leaf {
            let r = (self.r / self.children_count) as u8;
            let g = (self.g / self.children_count) as u8;
            let b = (self.b / self.children_count) as u8;
            let a = (self.a / self.children_count) as u8;

            let color = format!("#{:02x}{:02x}{:02x}{:02x}", r, g, b, a);
            *record.entry(color).or_insert(0) += self.children_count;
        } else {
            for child in &self.children {
                if let Some(child_node) = child {
                    child_node.colors_stats(record);
                }
            }
        }
    }
}

pub fn fast_blur(buffer: &mut [u32], x0: usize, y0: usize, x1: usize, y1: usize, width: usize) {
    let kernel_size = 3;
    let radius = kernel_size / 2;
    
    for y in y0..y1 {
        for x in x0..x1 {
            let mut sum_r = 0u32;
            let mut sum_g = 0u32;
            let mut sum_b = 0u32;
            let mut count = 0u32;

            for ky in -radius..=radius {
                for kx in -radius..=radius {
                    let nx = x as i32 + kx;
                    let ny = y as i32 + ky;

                    if nx >= 0 && ny >= 0 && nx < width as i32 && ny >= 0 {
                        let pixel = buffer[(ny as usize) * width + (nx as usize)];
                        sum_r += (pixel & 0xFF) as u32;
                        sum_g += ((pixel >> 8) & 0xFF) as u32;
                        sum_b += ((pixel >> 16) & 0xFF) as u32;
                        count += 1;
                    }
                }
            }
            
            let r = (sum_r / count) as u32 & 0xFF;
            let g = (sum_g / count) as u32 & 0xFF;
            let b = (sum_b / count) as u32 & 0xFF;
            buffer[y * width + x] = r | (g << 8) | (b << 16) | 0xFF000000;
        }
    }
}
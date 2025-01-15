#[cfg(test)]
mod test {
    use fluorescence::{
        color::{self, PrimanyColor},
        Image, RgbaColor,
    };
    use image::{GenericImageView, ImageReader};

    #[test]
    fn get_primany_colors_with_kmeans() {
        let image_file = "./example/len_std.jpg";
        let img = ImageReader::open(image_file).unwrap().decode().unwrap();

        let pixels: Vec<RgbaColor> = img
            .pixels()
            .map(|pixel| {
                let rgba = pixel.2;
                RgbaColor {
                    r: rgba[0],
                    g: rgba[1],
                    b: rgba[2],
                    a: rgba[3],
                }
            })
            .collect();

        let width = img.width();
        let heigth = img.height();

        let kmeans = color::kmeans::Kmeans::new(
            Image {
                pixels,
                width,
                heigth,
            },
            1,
            100,
            1.0,
        );

        let colors = kmeans.get_primary_colors().unwrap();

        println!("{:?}", colors);
    }
}

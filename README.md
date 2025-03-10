<h1 align="center">🌟 Fluorescence</h1>

🦀 Rust | 🥮 Moonbit

An image library for color, blur, transformation, and feature extraction.


## Blur


## Color

### Kmeans

#### 🦀 Rust
After installing this crates, We need to load the image from disk and pass it into a special data structure, which is prepared for `no_std` environments (such as bare metal environments or WASM).

```rust
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
```

#### 🥮 Moonbit

> When I found out that moonbit didn't even have a library that could read and parse jpeg or png images, it meant I needed some time to implement parsing images first. :(
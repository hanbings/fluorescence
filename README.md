<h1 align="center">🌟 Fluorescence</h1>

🦀 Rust | 🥮 Moonbit

An image library for color, blur, transformation, and feature extraction.

## Image

> This section is only provided for moonbit. There is no cake in moonbit that can load and parse images.
> 
> It is expected to support popular formats such as bmp, jpeg, png, etc.

### PNG

We have written a PNG file parser that currently detects the file header and basic color information of a PNG file, as well as the undecoded content of the PNG file including data chunks.

```moonbit
fn main {
  try
    @fs.read_file_to_bytes(
      "icons8-github-48.png",
    )
  catch {
    _ => println("error")
  } noraise {
    bytes => {
      try @png.parse_png(bytes.to_array()) catch {
        err => println(err)
      } noraise {
        data => println(data)
      }
      ()
    }
  }
}
```


## Hash

### Thumbhash

ThumbHash is a compact image placeholder format that can be directly embedded in JSON or stored in databases using Base64 encoding. It enables smooth visual transitions while the actual image is loading.

for moonbit, it can serve as a high-performance WebAssembly implementation embedded in web pages, allowing client-side image hashing and on-the-fly thumbnail generation during the loading process.

Its effect is as follows: after hashing, you obtain a short string that can be used as a placeholder while the actual image data is still loading.

![Demo](https://youke1.picui.cn/s1/2025/07/31/688a7153a9f61.png)


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
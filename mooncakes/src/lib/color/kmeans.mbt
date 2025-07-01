///|
pub(all) struct Kmeans {
  image : @lib.Image
  init_centroid : Int
  iteration : Int
  min_distance : Float
}

///| K-means clustering implementation for extracting primary colors from images
/// 
/// ### Parameters
/// - init_centroid: Number of initial cluster centers
/// - iteration:    Maximum iterations allowed
/// - min_distance: Convergence threshold for centroid changes (early stopping)
/// 
/// ### Algorithm Workflow
/// 1. Randomly initialize cluster centroids
/// 2. Iterate until convergence or max iterations reached:
///    a. Assign each pixel to nearest centroid
///    b. Recalculate centroids based on cluster means
///    c. Check centroid movement against threshold
/// 
/// ### Returns
/// Array of primary colors with length determined by init_centroid parameter
impl PrimanyColor for Kmeans with get_primary_colors(self) {
  let random = @random.Rand::new()
  let mut centroid : Array[@lib.RgbaColor] = (0)
    .until(self.init_centroid)
    .map(fn(_entry) {
      @lib.RgbaColor::{
        r: random.int(limit=255).to_byte(),
        g: random.int(limit=255).to_byte(),
        b: random.int(limit=255).to_byte(),
        a: random.int(limit=255).to_byte(),
      }
    })
    .collect()
  let center_cluster : Array[Array[@lib.RgbaColor]] = Array::makei(
    self.init_centroid,
    fn(_) { [] },
  )
  let mut iteration = self.iteration
  while iteration > 0 {
    iteration -= 1
    center_cluster.each(fn(cluster) { cluster.clear() })

    // calculate which particle is closest to each pixel
    for pixel in self.image.pixels {
      let dists = centroid.mapi(fn(index, center) {
        (index, @lib.RgbaColor::calc_dist(center, pixel))
      })

      // select the particle with the shortest distance
      let mut sort = dists[0]
      for index = 0; index < dists.length(); index = index + 1 {
        let dist = dists[index]
        if sort.1 < dist.1 {
          sort = dist
        }
      }
      center_cluster[sort.0].push(pixel)
    }

    // calculate a new set of centroid
    let new_centroid : Array[@lib.RgbaColor] = center_cluster.map(fn(cluster) {
      let acc : (Byte, Byte, Byte, Byte, Byte) = cluster.fold(
        init=(0, 0, 0, 0, 0),
        fn(acc : (Byte, Byte, Byte, Byte, Byte), pixel : @lib.RgbaColor) {
          (
            acc.0 + pixel.r,
            acc.1 + pixel.g,
            acc.2 + pixel.b,
            acc.3 + pixel.a,
            acc.4 + 1,
          )
        },
      )
      if acc.4 > 0 {
        return @lib.RgbaColor::{
          r: acc.0 / acc.4,
          g: acc.1 / acc.4,
          b: acc.2 / acc.4,
          a: acc.3 / acc.4,
        }
      }
      @lib.RgbaColor::{ r: 0, g: 0, b: 0, a: 255 }
    })

    // prevent infinite number of iterations, in fact we only need a certain degree of results.
    let mut is_settled = true
    new_centroid.each(fn(a) {
      centroid.each(fn(b) {
        if @lib.RgbaColor::calc_dist(a, b) > self.min_distance {
          is_settled = false
        }
      })
    })
    if is_settled {
      break
    }

    // replace the better set of centroid produced in this iteration
    centroid = new_centroid
  }
  centroid
}

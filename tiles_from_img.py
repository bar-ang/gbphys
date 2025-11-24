#!/usr/bin/env python3
import sys
import numpy as np
from PIL import Image
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt

def kmeans_reduce_colors(img_path, K):
    # Load image
    img = Image.open(img_path).convert("RGB")
    arr = np.array(img)

    # Flatten image to (num_pixels, 3)
    h, w, _ = arr.shape
    pixels = arr.reshape(-1, 3)

    # Run KMeans
    kmeans = KMeans(n_clusters=K, n_init="auto")
    labels = kmeans.fit_predict(pixels)

    # Reshape labels to (h, w)
    label_matrix = labels.reshape(h, w)

    return label_matrix

def concat_blocks(blocks, margin=1, fill_value=4):
    blocks = np.array(blocks)
    
    # Handle shape (N, h, w) by converting to a square grid
    if blocks.ndim == 3:
        N, h, w = blocks.shape
        cols = int(np.ceil(np.sqrt(N)))
        rows = int(np.ceil(N / cols))
        padded = np.zeros((rows * cols, h, w), dtype=blocks.dtype)
        padded[:N] = blocks
        blocks = padded.reshape(rows, cols, h, w)
    elif blocks.ndim == 4:
        rows, cols, h, w = blocks.shape
    else:
        raise ValueError("blocks must have shape (N, h, w) or (rows, cols, h, w)")
    
    # Compute output image size
    H = rows * h + (rows - 1) * margin
    W = cols * w + (cols - 1) * margin
    glued = np.full((H, W), fill_value, dtype=blocks.dtype)
    
    # Paste blocks with margins
    for r in range(rows):
        for c in range(cols):
            y = r * (h + margin)
            x = c * (w + margin)
            glued[y:y+h, x:x+w] = blocks[r, c]
    
    return glued
# FF FF - one row ==> 16 pairs
def block_to_tile(block):
    tile_rows = []
    for row in block:
        bbytes = [0, 0]
        for i, v in enumerate(row):
            bbytes[0] = (bbytes[0] << 1) | (int(v) & 1)
            bbytes[1] = (bbytes[1] << 1) | ((int(v) & 2) >> 1)            
        tile_rows.append(f"${bbytes[0]:02X},${bbytes[1]:02X}")
    return ", ".join(tile_rows)

def blocks_to_tiles(blocks):
    return [block_to_tile(block) for block in blocks]

def main():
    if len(sys.argv) < 2:
        print("Usage: python kmeans_color_reduce.py <image_path> [<K>]")
        sys.exit(1)

    img_path = sys.argv[1]
    if len(sys.argv) == 3:
        K = int(sys.argv[2])
    else:
        K = 4

    matrix = kmeans_reduce_colors(img_path, K)

    h, w = matrix.shape
    blocks = matrix.reshape(h // 16, 16, w // 16, 16)
    blocks = blocks.swapaxes(1, 2)
    blocks = blocks.reshape(-1, 16, 16)

    bh, bw = blocks[0].shape
    arranged = [0] * (4 * len(blocks))
    for i, block in enumerate(blocks):
        tiles = block.reshape(bh // 8, 8, bw // 8, 8)
        tiles = tiles.swapaxes(1, 2)
        tiles = tiles.reshape(-1, 8, 8)
        arranged[i] = tiles[0]
        arranged[i + 1*len(blocks)] = tiles[1]
        arranged[i + 2*len(blocks)] = tiles[2]
        arranged[i + 3*len(blocks)] = tiles[3]

    tiles_str = blocks_to_tiles(arranged) 

    with open("object.asm", "w") as f:
        f.write("SECTION \"Object\", ROM0\n")
        f.write("\nObject:\n")
        f.write("\n".join([f"db {t}" for t in tiles_str]))
        f.write("\nEndObject:\n")

    glued = concat_blocks(arranged, margin=0)
    plt.imshow(glued)
    plt.show()

if __name__ == "__main__":
    main()


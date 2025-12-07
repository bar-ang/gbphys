import sys
from PIL import Image

def image_to_matrix(path, color_map):
    """
    Convert an image into a matrix where each unique color becomes an integer ID.
    Returns (matrix, color_map).
    """

    img = Image.open(path).convert("RGB")
    width, height = img.size
    pixels = img.load()

    next_id = 0

    matrix = []

    for y in range(height):
        row = []
        for x in range(width):
            rgb = pixels[x, y]

            if rgb not in color_map:
                raise Exception(f"unexpected color: {rgb}")

            row.append(color_map[rgb])
        matrix.append(row)

    return matrix

def make_tilemap(f, matrix, max_width=32):
    for i, row in enumerate(matrix):
        full_row = row + [0] * (max_width - len(row))
        f.write("db " + ", ".join([f"${v:02X}" for v in full_row]) + "\n") 

def main():
    matrix = image_to_matrix(sys.argv[1], color_map={
            (255, 255, 255): 0,
            (0, 0, 0):       1,
            (15, 0, 255):    2
        }
    )

    with open("assets/tilemap.asm", "w") as f:
        make_tilemap(f, matrix)


if __name__ == "__main__":
    sys.exit(main() or 0)

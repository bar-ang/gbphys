import sys
import json

def main(json_file, output_file):
    with open(json_file, "r") as f:
        js = json.load(f)

    with open(output_file, "wb") as f:
        for row in js:
            f.write(bytes(row))

    return 0

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("must provide JSON file")
        sys.exit(-1)

    with open(sys.argv[1], "r") as f:
        j = json.load(f)

    json_file = sys.argv[1]
    out_file = "tilemap.2bpp"
    if len(sys.argv) > 2:
        out_file = sys.argv[2]
        
    sys.exit(main(json_file, out_file) or 0)
    

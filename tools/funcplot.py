import sys
from functools import partial
import math

FILE = "assets/pseudo_math.asm"

ROW_LEN = 8
JUMP_TIME = 90
JUMP_HEIGHT = 32

def parabola(x, t, m):
    return 4*m*x*(t-x) / (t*t)

def sine(x, t, m):
    return m * math.sin(2 * math.pi * x / t)
def cosine(x, t, m):
    return m * math.cos(2 * math.pi * x / t)

def burn_func(file, func, name, to, fromm=0, labels={}):
    name = name.capitalize()
    rounds = [round(func(x+1)) - round(func(x)) for x in range(fromm, to)]
    rows = [f"Pseudo{name}: ;Num Frames: {to - fromm}"]

    accum = []

    for i, r in enumerate(rounds):
        if i in labels:
            rows.append(f".{labels[i].lower()}:")
        accum.append(f"${(r & 0xff):02X}")

        if len(accum) >= ROW_LEN or (i+1) in labels or i == len(rounds)-1:
            rows.append(f"db {", ".join(accum)}")
            accum = []

    rows.append(f"EndPseudo{name}:")
    file.write("\n".join(rows) + "\n\n")

def main():
    parabola0 = partial(parabola, t=JUMP_TIME, m=JUMP_HEIGHT)
    sine0 = partial(sine, t=140, m=12)
    cosine0 = partial(cosine, t=140, m=12)
    
    with open(FILE, "w") as f:
        f.write("SECTION \"Pseudo Math\", ROM0\n\n")
        burn_func(f, parabola0, "Parabola", 2*JUMP_TIME, labels={
            JUMP_TIME//2: "maximum",
            JUMP_TIME: "equalibrium"
        })
        burn_func(f, sine0, "Sine", 140, labels={})
        burn_func(f, cosine0, "Cosine", 140, labels={})


    return 0

if __name__ == "__main__":
    sys.exit(main() or 0)

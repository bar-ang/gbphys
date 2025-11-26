import sys
from functools import partial

FILE = "assets/pseudo_math.asm"

ROW_LEN = 8
JUMP_TIME = 90
JUMP_HEIGHT = 32

def parabola(x, t, m):
    return 4*m*x*(t-x) / (t*t)

def burn_func(file, func, name, to, fromm=0, labels={}):
    rounds = [round(func(x+1)) - round(func(x)) for x in range(fromm, to+1)]
    rows = [f"Pseudo{name.capitalize()}:"]

    accum = []

    for i, r in enumerate(rounds):
        if i in labels:
            rows.append(f".{labels[i].lower()}:")
        accum.append(f"${(r & 0xff):02X}")

        if len(accum) >= ROW_LEN or (i+1) in labels or i == len(rounds)-1:
            rows.append(f"db {", ".join(accum)}")
            accum = []

    rows.append(f"End{rows[0]}")
    file.write("\n".join(rows))

def main():
    parabola0 = partial(parabola, t=JUMP_TIME, m=JUMP_HEIGHT)
    
    with open(FILE, "w") as f:
        f.write("SECTION \"Pseudo Math\", ROM0\n\n")
        burn_func(f, parabola0, "Parabola", 2*JUMP_TIME, labels={
            JUMP_TIME//2: "maximum",
            JUMP_TIME: "equalibrium"
        })


    return 0

if __name__ == "__main__":
    sys.exit(main() or 0)

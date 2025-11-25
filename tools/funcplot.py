import sys
from functools import partial

ROW_LEN = 8
JUMP_TIME = 90
JUMP_HEIGHT = 32

def func(x, t, m):
    return 4*m*x*(t-x) / (t*t)

def main(t, m):
    f = partial(func, t=t, m=m)
    rounds = [round(f(x+1)) - round(f(x)) for x in range(t+1)]
    unsigned = [x & 0xff for x in rounds][::-1]
    hexs = [f"${t:02X}" for t in unsigned]
    chunks = [hexs[i:i+ROW_LEN] for i in range(0, len(hexs), ROW_LEN)]
    rows = ["JumpFunc:"]
    for chunk in chunks:
        rows.append("db " + ",".join(chunk))
    rows.append("EndJumpFunc:")

        
    with open("assets/jump_func.asm", "w") as f:
        f.write("\n".join(rows))

    return 0

if __name__ == "__main__":
    sys.exit(main(JUMP_TIME, JUMP_HEIGHT) or 0)

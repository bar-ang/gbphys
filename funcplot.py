import sys
from functools import partial

def func(x, t, m):
    return 4*m*x*(t-x) / (t*t)

def main(t, m):
    f = partial(func, t=t, m=m)
    rounds = [round(f(x+1)) - round(f(x)) for x in range(t)]
    unsigned = [x & 0xff for x in rounds]
    bbs = bytes(unsigned[::-1])
    print(bbs)
    with open("jump_func.bin", "wb") as f:
        f.write(bbs)

    return 0

if __name__ == "__main__":
    sys.exit(main(90, 32) or 0)

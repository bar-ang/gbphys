rgbasm -o $1.o $1.asm &&
rgblink -o $1.gb $1.o &&
rgbfix -v -p 0xFF $1.gb

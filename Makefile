# Game Boy build Makefile
# Usage:
#   make GAME=mygame
# or set GAME variable inside this file.

# Default game name (without extension)
GAME ?= main

# Tools
RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

# Flags
RGBFIXFLAGS = -v -p 0xFF

# Targets
all: $(GAME).gb

$(GAME).o: $(GAME).asm
	$(RGBASM) -o $@ $<

$(GAME).gb: $(GAME).o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) $(RGBFIXFLAGS) $@

clean:
	rm -f $(GAME).o $(GAME).gb

.PHONY: all clean


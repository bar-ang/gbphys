# Game Boy build Makefile
# Usage:
#   make GAME=mygame
# or set GAME variable inside this file.

# Default game name (without extension)
GAME ?= phys

# ----------------------------------------
# Directories
# ----------------------------------------
SRC_DIR ?= src
ASSETS_DIR ?= assets
BUILD_DIR ?= build

# ----------------------------------------
# Collect all files recursively
# ----------------------------------------
SRC_FILES := $(shell find $(SRC_DIR) -type f)
ASSET_FILES := $(shell find $(ASSETS_DIR) -type f)

ALL_INPUTS := $(SRC_FILES) $(ASSET_FILES)

# Output file
TARGET := $(BUILD_DIR)/$(GAME)

# Tools
RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

# Flags
RGBFIXFLAGS = -v -p 0xFF

# Default rule
all: $(TARGET).gb

# ----------------------------------------
# Rule to build output
# Re-run this rule if ANY source/asset changes
# ----------------------------------------
$(TARGET).o: $(ALL_INPUTS)
	@mkdir -p $(BUILD_DIR)
	$(RGBASM) -o $@ $(SRC_DIR)/$(GAME).asm


$(TARGET).gb: $(TARGET).o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) $(RGBFIXFLAGS) $@

# ----------------------------------------
# Cleaning
# ----------------------------------------
clean:
	rm -rf $(BUILD_DIR)


.PHONY: all clean


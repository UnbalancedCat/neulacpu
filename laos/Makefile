LA_BIN_PATH	:= $(CURDIR)/../ext/loongarch32r-linux-gnusf-2022-05-20/bin
LA_PREFIX	:= loongarch32r-linux-gnusf-

CC	:= $(LA_BIN_PATH)/$(LA_PREFIX)gcc
CXX := $(LA_BIN_PATH)/$(LA_PREFIX)g++
OD	:= $(LA_BIN_PATH)/$(LA_PREFIX)objdump
OC	:= $(LA_BIN_PATH)/$(LA_PREFIX)objcopy

CMAKE	:= cmake

BUILD_DIR := build
$(shell mkdir -p $(BUILD_DIR))

BIN		:= neula-os
COMMON_DIR	:= COMMON

FILES	:= $(shell find src -name *.c)

.PHONY: build clean

build:
	$(CC) $(FILES) -o $(BUILD_DIR)/$(BIN)
	$(OD) -D $(BUILD_DIR)/$(BIN) > $(BUILD_DIR)/$(BIN).dump

clean:
	rm -rf $(BUILD_DIR)
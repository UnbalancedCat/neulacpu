LA_BIN_PATH	:= $(CURDIR)/../ext/loongarch32r-linux-gnusf-2022-05-20/bin
LA_PREFIX	:= loongarch32r-linux-gnusf-

CC	:= $(LA_BIN_PATH)/$(LA_PREFIX)gcc
CXX := $(LA_BIN_PATH)/$(LA_PREFIX)g++
OD	:= $(LA_BIN_PATH)/$(LA_PREFIX)objdump
OC	:= $(LA_BIN_PATH)/$(LA_PREFIX)objcopy
RE	:= $(LA_BIN_PATH)/$(LA_PREFIX)readelf

NPROC	:= $(shell nproc)

CMAKE	:= cmake

BUILD_DIR 	:= build
ABS_BUILD	:= $(CURDIR)/$(BUILD_DIR)
$(shell mkdir -p $(BUILD_DIR))

BIN			:= neula-os
BINARY		:= $(BUILD_DIR)/$(BIN)

TOP_SRC_DIR	:= src
MODULES		:= kernel util
SOURCE_DIRS	:= $(addprefix $(TOP_SRC_DIR)/,$(MODULES))
MK_DIRS		:= $(addprefix MAKE/,$(SOURCE_DIRS))
ALL_SRCS	:= $(shell find . -name '*.c')
LD_CSRIPT	:= kernel.ld

EXTRA_MACRO	:= # NDEBUG

EXTRA_FLAGS =  -Wall -Werror -O0 -fno-omit-frame-pointer -ggdb -gdwarf-2
EXTRA_FLAGS += -mfpu=none -march=loongarch32r -mabi=ilp32s
EXTRA_FLAGS += -MD
EXTRA_FLAGS += -ffreestanding -fno-common -nostdlib
EXTRA_FLAGS += -I.
EXTRA_FLAGS += -fno-pie -no-pie
EXTRA_FLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

COMMONFLAGS	:= $(EXTRA_FLAGS)
CPPFLAGS	+= $(addprefix -D,$(EXTRA_MACRO)) -I$(CURDIR)/include
CFLAGS		+= $(COMMONFLAGS)
LDFLAGS		+= $(COMMONFLAGS) -z max-page-size=4096 -T$(LD_CSRIPT)

.PHONY: all build clean

all: build

$(MK_DIRS): MAKE/%:% $(shell find $(%) -name '*.c')
	@TOP_BUILD_DIR=$(ABS_BUILD) \
	CC=$(CC)					\
	CPPFLAGS="$(CPPFLAGS)"		\
	CFLAGS="$(CFLAGS)"			\
	LDFLAGS="$(LDFLAGS)"		\
	$(MAKE) -C $< -j$(NPROC)

build: $(MK_DIRS)
	@$(CC) -o $(BINARY) $(shell find $(BUILD_DIR) -name '*.o') $(CPPFLAGS) $(CFLAGS) $(LDFLAGS)
	@$(OD) -D $(BINARY) > $(BINARY).dump
	@$(RE) -a $(BINARY) > $(BINARY).info
	@$(OC) $(BINARY) -O binary $(BINARY).bin

clean:
	rm -rf $(BUILD_DIR)


# use native

clean-usr:
	rm -rf $(BUILD_DIR)/user

usr:
	@TOP_BUILD_DIR=$(ABS_BUILD) \
	CPPFLAGS="$(CPPFLAGS)"		\
	$(MAKE) native -C $(TOP_SRC_DIR)/user -j$(NPROC)

tcpl:
	$(CC) --target-help

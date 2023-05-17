CURNAME		:= kernel
BUILD_DIR	:= $(TOP_BUILD_DIR)/$(CURNAME)

CSRC		:= $(wildcard *.c)
OBJS		:= $(patsubst %.c,%.o,$(CSRC))
BUILD_OBJS	:= $(addprefix $(BUILD_DIR)/,$(OBJS))

ASSRC		:= $(wildcard *.S)
ASOBJ		:= $(patsubst %.S,%.o,$(ASSRC))
BUILD_ASOBJ	:= $(addprefix $(BUILD_DIR)/,$(ASOBJ))

.PHONY: build all message

all: message build

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_OBJS): $(BUILD_DIR)/%.o:%.c $(BUILD_DIR)
	@$(CC) -c -o $@ $< $(CPPFLAGS) $(CFLAGS)

$(BUILD_ASOBJ): $(BUILD_DIR)/%.o:%.S $(BUILD_DIR)
	@$(CC) -c -o $@ $< $(CPPFLAGS) $(CFLAGS)

build: $(BUILD_OBJS) $(BUILD_ASOBJ)

message:
	@echo "building $(CURNAME)"

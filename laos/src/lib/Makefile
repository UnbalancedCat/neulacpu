CURNAME		:= lib
BUILD_DIR	:= $(TOP_BUILD_DIR)/$(CURNAME)

CSRC		:= $(wildcard *.c)
OBJS		:= $(patsubst %.c,%.o,$(CSRC))
BUILD_OBJS	:= $(addprefix $(BUILD_DIR)/,$(OBJS))

.PHONY: build all message

all: message build

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_OBJS): $(BUILD_DIR)/%.o:%.c $(BUILD_DIR)
	@$(CC) -c -o $@ $< $(CPPFLAGS) $(CFLAGS)

build: $(BUILD_OBJS)

message:
	@echo "building $(CURNAME)"
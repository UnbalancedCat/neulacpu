CURNAME		:= user
BUILD_DIR	:= $(TOP_BUILD_DIR)/$(CURNAME)

CSRC		:= $(wildcard *.c)
OBJS		:= $(patsubst %.c,%.o,$(CSRC))
BUILD_OBJS	:= $(addprefix $(BUILD_DIR)/,$(OBJS))
BASENAMES	:= $(basename $(CSRC))
BUILD_EXE	:= $(addprefix $(BUILD_DIR)/,$(BASENAMES))

.PHONY: build all message

all: message build

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_OBJS): $(BUILD_DIR)/%.o:%.c $(BUILD_DIR)
	@$(CC) -c -o $@ $< $(CPPFLAGS) $(CFLAGS)

$(BUILD_EXE): %:%.o
	@$(CC) -o $@ $< $(CPPFLAGS) $(CFLAGS)

build: $(BUILD_EXE)

message:
	@echo "building $(CURNAME)"

native: $(BUILD_EXE)
	@echo $(BASENAMES)

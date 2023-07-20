default:
	@echo "Hello World!"

submodue-update-init:
	git submodule update --init

# prepare loongarch toolchain

TOOLCHAIN_PK	:= loongarch64-linux-gnu/toolchain-loongarch64-linux-gnu-gcc8-host-x86_64-2022-07-18.tar.xz

LA_PATH			:= ext/toolchain-loongarch64-linux-gnu-gcc8-host-x86_64-2022-07-18/bin
LA_ARCH			:= loongarch64-linux-gnu-
LA				:= $(LA_PATH)/$(LA_ARCH)

GCC				:= $(LA)gcc
OD				:= $(LA)objdump
OC				:= $(LA)objcopy
RE				:= $(LA)readelf

LA_TOOLS		:= $(GCC) $(OD) $(OC) $(RE)

unpk-gcc: submodue-update-init
	mkdir -p ext
	tar -xvf $(TOOLCHAIN_PK) -C ext

$(LA_TOOLS): unpk-gcc

# prepare loongarch source code


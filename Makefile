default:
	@echo "Hello World!"
	@echo $(CURDIR)

submodue-update-init:
	git submodule update --init

# prepare loongarch toolchain

TOOLCHAIN_URL	:= https://gitee.com/loongson-edu/la32r-toolchains/releases/download/v0.0.2/loongarch32r-linux-gnusf-2022-05-20-x86.tar.gz
LA_GDB_URL		:= https://gitee.com/loongson-edu/la32r-toolchains/releases/download/v0.0.2/loongarch32r-linux-gnusf-gdb-x86

TOOLCHAIN_TAR	:= $(notdir $(TOOLCHAIN_URL))
LA_GDB_TAR		:= $(notdir $(LA_GDB_URL))

$(TOOLCHAIN_TAR):
	wget $(TOOLCHAIN_URL)

ext/$(TOOLCHAIN_TAR):
	tar -zxvf $(notdir $@)
	mv loongarch32r-linux-gnusf-* ext

lagcc: ext/$(TOOLCHAIN_TAR)

LA_ARCH			:= loongarch32r-linux-gnusf-

# prepare busybox

BUSYBOX_URL		:= https://gitee.com/loongson-edu/la32r-Linux/releases/download/v0.2/initrd_d.tar.gz
BUSYBOX_TAR		:= $(notdir $(BUSYBOX_URL))

$(BUSYBOX_TAR):
	wget $(BUSYBOX_URL)

ext/$(BUSYBOX_TAR): $(BUSYBOX_TAR)
	tar -xvf $(notdir $@)
	mv initrd_d* ext

busybox: ext/$(BUSYBOX_TAR)

# prepare loongarch linux source code

LALX_URL		:= https://gitee.com/loongson-edu/la32r-Linux
LALX_TAR		:= $(notdir $(LALX_URL))

$(LALX_TAR):
	wget $(LALX_URL)

ext/$(LALX_TAR): $(LALX_TAR)
	tar -xvf $(notdir $@)
	mv v0.2* ext

lalx: ext/$(LALX_TAR)

# prepare loongarch source code

xv6: lagcc
	TOOLPREFIX=$(CURDIR)/$(shell find ext -type d -name '$(LA_ARCH)*')/bin/$(LA_ARCH) \
	$(MAKE) -C lasoft/xv6-la build

xv6-clean:
	$(MAKE) -C lasoft/xv6-la clean

clean-latc:
	rm -r ext/*

# Shared SNES C Compiler Build Configuration
# This file contains all compiler configurations, source definitions, and build rules

# Set default shell
SHELL = /bin/sh

# Set default paths (can be overridden by individual projects)
SHARED_SRC_DIR ?= ../src
SHARED_PORT_DIR ?= ../port
BUILD_DIR ?= build

# =============================================================================
# TOOLCHAIN PATHS (Modify these or add to your $PATH)
# =============================================================================
WDC_PATH ?= /opt/wdc
CALYPSI_PATH ?= /opt/calypsi/bin
CC65_PATH ?= /usr/bin
LLVM_MOS_PATH ?= /usr/local
VBCC_PATH ?= /opt/vbcc

# Check if compiler is specified
ifneq ($(filter help clean wdc vbcc calypsi llvm-mos cc65 jcc816 tcc816,$(MAKECMDGOALS)),)
# Skip compiler check for help, clean, and convenience targets
else
ifeq ($(COMPILER),)
$(error Please specify a compiler. Usage: make COMPILER=wdc816cc, make COMPILER=vbcc65816, etc.)
endif
endif

# Normalizing Compiler Name (Lower case)
COMPILER_LOWER = $(shell echo $(COMPILER) | tr A-Z a-z)

# =============================================================================
# COMPILER CONFIGURATIONS
# =============================================================================

# WDC816CC Configuration
ifeq ($(COMPILER_LOWER),wdc816cc)
	CC = wine $(WDC_PATH)/bin/wdc816cc.exe
	AS = wine $(WDC_PATH)/bin/wdc816as.exe
	LD = wine $(WDC_PATH)/bin/wdcln.exe
	CCFLAGS = -WL -SM -MK -MT -ML -WP -MU -MV -SI -SP -D__WDC816CC__=1
	INCLUDES = -I"$(WDC_PATH)/Tools/include" -I"$(SHARED_SRC_DIR)" -I"lib" -I"include"
	
	ifeq ($(USE_FLOATING_POINT),1)
		LDFLAGS = -HB -ML -B -E -T -C018000,008000 $(PROJECT_OBJECTS) $(BUILD_DIR)/vectors.obj -C028000,010000 $(BUILD_DIR)/kernel.obj $(BUILD_DIR)/initsnes.obj -D7E2000,18000 -K048000,20000 -Lml -Lcl -O$(BUILD_DIR)/mainBankZero.bin
	else
		LDFLAGS = -HB -ML -B -E -T -C018000,008000 $(PROJECT_OBJECTS) $(BUILD_DIR)/vectors.obj -C028000,010000 $(BUILD_DIR)/kernel.obj $(BUILD_DIR)/initsnes.obj -D7E2000,18000 -K048000,20000 -Lcl -O$(BUILD_DIR)/mainBankZero.bin
	endif
	
	OUTPUT_EXT = .bin
	POST_LINK = if [ -f "$(BUILD_DIR)/mainBankZero.bin" ]; then cp "$(BUILD_DIR)/mainBankZero.bin" "$(BUILD_DIR)/mainBankZero_wdc816cc.smc"; fi
endif

# VBCC65816 Configuration
ifeq ($(COMPILER_LOWER),vbcc65816)
	export PATH := $(PATH):/home/god/Documents/vbcc/vbcc65816_linux/vbcc/bin
	CC = vc
	AS = vasm65816_oldstyle
	LD = vlink
	CCFLAGS = +snes-hi -lm -maxoptpasses=300 -O3 -inline-depth=1000 -unroll-all -fp-associative -force-statics -range-opt -I"$(SHARED_SRC_DIR)" -I"lib" -I"include" -D__VBCC__=1 -DLUA_CROSS_COMPILER -D__VBCC65816__ -c
	ASFLAGS = -816 -quiet -nowarn=62 -opt-branch -ldots -Fvobj
	LDFLAGS = +snes-hi -lm -maxoptpasses=300 -O -inline-depth=1000 -unroll-all -fp-associative -force-statics -range-opt -I"$(SHARED_SRC_DIR)" -I"lib" -I"include" -D__VBCC__=1 -D__VBCC65816__
	OUTPUT_EXT = .smc
endif

# Calypsi Configuration
ifeq ($(COMPILER_LOWER),calypsi)
	CC = $(CALYPSI_PATH)/cc65816
	AS = $(CALYPSI_PATH)/cc65816
	LD = $(CALYPSI_PATH)/ln65816
	
	ifeq ($(ROM_TYPE),huge)
		CCFLAGS += --core=65816 -O0 --code-model=large --data-model=huge --target=SNES -D__CALYPSI__=1
		STDLIB = $(CALYPSI_PATH)/../lib-huge/clib-huge.a
		LDFLAGS = --raw-multiple-memories --rom-code --no-tree-shaking --no-copy-initialize huge
	else
		CCFLAGS += --core=65816 -O2 --speed --code-model=large --data-model=large --target=SNES -D__CALYPSI__=1
		STDLIB = $(CALYPSI_PATH)/../lib/clib-lc-ld-snes.a
		LDFLAGS = --raw-multiple-memories --rom-code
	endif
	
	INCLUDES = -I"$(SHARED_SRC_DIR)" -I"lib" -I"include"
	OUTPUT_EXT = .smc
	
	ifeq ($(ROM_MAPPING),HiROM)
		LINKER_SCRIPT = $(SHARED_PORT_DIR)/calypsi/linker-large-large-HiROM.scm
		POST_LINK = python3 $(SHARED_PORT_DIR)/calypsi/ConvertIntelHex_HiROM.py $(BUILD_DIR)/calypsi.hex $(BUILD_DIR)/mainBankZero_calypsi.smc
	else
		LINKER_SCRIPT = $(SHARED_PORT_DIR)/calypsi/linker-large-large-LoROM.scm
		POST_LINK = python3 $(SHARED_PORT_DIR)/calypsi/ConvertIntelHex_LoROM.py $(BUILD_DIR)/calypsi.hex $(BUILD_DIR)/mainBankZero_calypsi.smc
	endif
endif

# LLVM-Mos Configuration (ELF-based flow)
ifeq ($(COMPILER_LOWER),llvm-mos)
	LLVM_MOS_SDK_ROOT ?= /media/gamesSteam/llvm-mos-sdk-snes
	LLVM_MOS_BIN_DIR ?= $(LLVM_MOS_SDK_ROOT)/_deps/llvm-mos-src/bin
	LLVM_MOS_PLATFORM_ROOT ?= $(LLVM_MOS_SDK_ROOT)/mos-platform/build/install/mos-platform

	CC = $(LLVM_MOS_BIN_DIR)/mos-clang
	AS = $(LLVM_MOS_BIN_DIR)/mos-clang
	LD = $(LLVM_MOS_BIN_DIR)/mos-clang
	NM = $(LLVM_MOS_BIN_DIR)/llvm-nm
	OBJCOPY = $(LLVM_MOS_BIN_DIR)/llvm-objcopy

	CCFLAGS = -mcpu=mosw65816 \
		      -I"$(LLVM_MOS_PLATFORM_ROOT)/common/include" \
	          -I"$(LLVM_MOS_PLATFORM_ROOT)/snes/include" \
	          -I"$(SHARED_SRC_DIR)" -Iinclude -Oz -flto -fnonreentrant -ffast-math \
	          -funroll-loops -finline-functions -fomit-frame-pointer \
	          -fno-stack-protector -fdata-sections -ffunction-sections 

	LDFLAGS = -T $(SHARED_PORT_DIR)/llvm-mos/linker.ld \
	          -L"$(LLVM_MOS_PLATFORM_ROOT)/snes/lib" \
	          -lzero-bss -lcopy-data -lcopy-zp-data -linit-stack -lc -lexit-loop \
	          -Wl,-Map=$(BUILD_DIR)/mainBankZero_llvm-mos.map

	OUTPUT_EXT = .smc
endif

# CC65 Configuration
ifeq ($(COMPILER_LOWER),cc65)
	CC = cc65
	AS = ca65
	LD = ld65
	CCFLAGS = -t none -O -I$(SHARED_SRC_DIR) -Iinclude -D__CC65__=1
	LDFLAGS = -C $(SHARED_PORT_DIR)/cc65/snes.cfg -o -m $(BUILD_DIR)/mainBankZero_cc65.map --no-smc
	OUTPUT_EXT = .smc
endif

# =============================================================================
# SOURCE CONFIGURATIONS
# =============================================================================

# Default project source logic (shared by most compilers)
PROJECT_C_FILES = $(wildcard *.c)

ifeq ($(COMPILER_LOWER),wdc816cc)
	C_SOURCES = $(PROJECT_C_FILES) $(SHARED_PORT_DIR)/wdc816cc/lorom/kernel.c $(SHARED_SRC_DIR)/initsnes.c
	ASM_SOURCES = $(SHARED_PORT_DIR)/wdc816cc/lorom/vectors.asm
	OBJECTS = $(addprefix $(BUILD_DIR)/,$(addsuffix .obj,$(basename $(PROJECT_C_FILES)))) $(BUILD_DIR)/kernel.obj $(BUILD_DIR)/initsnes.obj $(BUILD_DIR)/vectors.obj
	vpath %.c $(SHARED_PORT_DIR)/wdc816cc/lorom $(SHARED_SRC_DIR) .
	vpath %.asm $(SHARED_PORT_DIR)/wdc816cc/lorom
endif

ifeq ($(COMPILER_LOWER),llvm-mos)
	C_SOURCES = $(PROJECT_C_FILES) $(SHARED_SRC_DIR)/initsnes.c $(SHARED_PORT_DIR)/llvm-mos/putchar_stub.c
	ASM_SOURCES = $(SHARED_PORT_DIR)/llvm-mos/startup.s $(SHARED_PORT_DIR)/llvm-mos/vectors.s
	vpath %.c $(SHARED_SRC_DIR) $(SHARED_PORT_DIR)/llvm-mos .
	vpath %.s $(SHARED_PORT_DIR)/llvm-mos
endif

# Standard Object definition for modern toolchains
ifeq ($(filter vbcc65816 calypsi cc65 tcc816,$(COMPILER_LOWER)),$(COMPILER_LOWER))
	OBJECTS = $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(PROJECT_C_FILES)))) $(BUILD_DIR)/initsnes.o
	vpath %.c $(SHARED_SRC_DIR) .
endif

# =============================================================================
# BUILD RULES
# =============================================================================

all: $(BUILD_DIR)
ifeq ($(COMPILER_LOWER),wdc816cc)
	@$(MAKE) $(OBJECTS)
	$(LD) $(LDFLAGS)
	$(POST_LINK)
else ifeq ($(COMPILER_LOWER),calypsi)
	@$(MAKE) $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) $(LINKER_SCRIPT) $(STDLIB) --output-format=intel-hex -o $(BUILD_DIR)/calypsi.hex
	$(POST_LINK)
else ifeq ($(COMPILER_LOWER),llvm-mos)
	@echo "Compiling with LLVM-MOS..."
	# 1. Link directly to the .smc file. 
	# The linker script's "FULL()" commands will build the ROM into this file.
	# mos-clang will automatically create a debug file named mainBankZero_llvm-mos.smc.elf
	$(CC) $(CCFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/mainBankZero_llvm-mos.smc $(C_SOURCES) $(ASM_SOURCES)
	
	@echo "Generating Symbol File..."
	# 2. Extract symbols from the sidecar ELF created by the compiler
	# Note the .elf appended to the output name
	@$(NM) --numeric-sort $(BUILD_DIR)/mainBankZero_llvm-mos.smc.elf | \
		awk '$$3 != "" { print $$1 " " $$3 }' \
		> $(BUILD_DIR)/mainBankZero_llvm-mos.sym
		
	@echo "Compilation successful. ROM: mainBankZero_llvm-mos.smc"
else ifeq ($(COMPILER_LOWER),vbcc65816)
	@$(MAKE) $(OBJECTS)
	$(CC) $(LDFLAGS) $(C_SOURCES) -o $(BUILD_DIR)/mainBankZero_vbcc65816$(OUTPUT_EXT)
else ifeq ($(COMPILER_LOWER),cc65)
	@$(MAKE) $(OBJECTS)
	$(LD) -C $(SHARED_PORT_DIR)/cc65/snes.cfg -o $(BUILD_DIR)/mainBankZero_cc65$(OUTPUT_EXT) $(OBJECTS) lib/none.lib
else
	@echo "Unsupported or unknown compiler: $(COMPILER)"
endif

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Pattern Rules
$(BUILD_DIR)/%.obj: %.c
	$(CC) $(CCFLAGS) $(INCLUDES) -o $@ $<

$(BUILD_DIR)/%.obj: %.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CCFLAGS) $(INCLUDES) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
	rm -f *.obj *.o *.bin *.smc *.elf *.sym *.hex *.map
	@echo Clean complete!

.PHONY: all clean llvm-mos vbcc65816 calypsi cc65 wdc
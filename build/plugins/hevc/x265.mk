PKG             := x265
$(PKG)_WEBSITE  := http://x265.org/
$(PKG)_DESCR    := H.265/HEVC video stream encoder.
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 3.5
$(PKG)_CHECKSUM := e70a3335cacacbba0b3a20ec6fecd6783932288ebc8163ad74bcc9606477cae8
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/x265-[0-9]*.patch)))
$(PKG)_SUBDIR   := x265_$($(PKG)_VERSION)
$(PKG)_FILE     := x265_$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://bitbucket.org/multicoreware/x265_git/downloads/$($(PKG)_FILE)
$(PKG)_URL_2    := https://download.videolan.org/pub/videolan/x265/$(x265_FILE)
$(PKG)_DEPS     := cc $(BUILD)~nasm

define $(PKG)_UPDATE
    $(WGET) -q -O- https://download.videolan.org/pub/videolan/x265/ | \
    $(SED) -n 's,.*">x265_\([0-9][^<]*\)\.t.*,\1,p' | \
    tail -1
endef

# `-DENABLE_DYNAMIC_HDR10=ON` -> `-DENABLE_HDR10_PLUS=ON`
# x265 requires nasm 2.13 or newer (instead than yasm) after release 2.6.
define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && mkdir -p 10bit 12bit

    # Fix ARM NEON includes when building the 10/12bit libraries
    # https://bitbucket.org/multicoreware/x265_git/issues/549/fail-to-build-for-aarch64-and-armhf
    $(SED) -i 's/PFX(\(.*\))/x265_\1/g' '$(SOURCE_DIR)/source/common/aarch64/asm-primitives.cpp'

    # 12 bit
    cd '$(BUILD_DIR)/12bit' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=ON \
        -DEXPORT_C_API=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_ASSEMBLY=$(if $(call seq,64,$(BITS)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DENABLE_HDR10_PLUS=ON \
        -DMAIN12=ON \
        -DCROSS_COMPILE_ARM=$(if $(IS_X86),OFF,ON)

    $(MAKE) -C '$(BUILD_DIR)/12bit' -j '$(JOBS)'
    cp '$(BUILD_DIR)/12bit/libx265.a' '$(BUILD_DIR)/libx265_main12.a'

    # 10 bit
    cd '$(BUILD_DIR)/10bit' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=ON \
        -DEXPORT_C_API=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_ASSEMBLY=$(if $(call seq,64,$(BITS)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DENABLE_HDR10_PLUS=ON \
        -DCROSS_COMPILE_ARM=$(if $(IS_X86),OFF,ON)

    $(MAKE) -C '$(BUILD_DIR)/10bit' -j '$(JOBS)'
    cp '$(BUILD_DIR)/10bit/libx265.a' '$(BUILD_DIR)/libx265_main10.a'

    # 8bit
    cd '$(BUILD_DIR)' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=OFF \
        -DEXPORT_C_API=ON \
        -DENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DENABLE_ASSEMBLY=$(if $(call seq,64,$(BITS)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DENABLE_HDR10_PLUS=ON \
        -DEXTRA_LIB='x265_main10.a;x265_main12.a' \
        -DEXTRA_LINK_FLAGS=-L'$(BUILD_DIR)' \
        -DLINKED_10BIT=ON \
        -DLINKED_12BIT=ON \
        -DCROSS_COMPILE_ARM=$(if $(IS_X86),OFF,ON)

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(subst -,/,$(INSTALL_STRIP_LIB))

    $(if $(BUILD_SHARED), \
        rm -f '$(PREFIX)/$(TARGET)/lib/libx265.a' && \
        $(SED) -i 's/^\(Cflags:.* \)/\1-DX265_API_IMPORTS=1 /g' '$(PREFIX)/$(TARGET)/lib/pkgconfig/x265.pc' \
    $(else), \
        $(INSTALL) '$(BUILD_DIR)/libx265_main12.a' '$(PREFIX)/$(TARGET)/lib/libx265_main12.a' && \
        $(INSTALL) '$(BUILD_DIR)/libx265_main10.a' '$(PREFIX)/$(TARGET)/lib/libx265_main10.a' && \
        $(SED) -i 's|-lx265|-lx265 -lx265_main10 -lx265_main12|' '$(PREFIX)/$(TARGET)/lib/pkgconfig/x265.pc')

    '$(TARGET)-gcc' \
        -W -Wall -Werror \
        '$(TOP_DIR)/src/$(PKG)-test.c' \
        -o '$(PREFIX)/$(TARGET)/bin/test-$(PKG).exe' \
        `$(TARGET)-pkg-config --cflags --libs $(PKG)`
endef

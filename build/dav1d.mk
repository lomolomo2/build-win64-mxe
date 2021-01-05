PKG             := dav1d
$(PKG)_WEBSITE  := https://code.videolan.org/videolan/dav1d
$(PKG)_DESCR    := dav1d is a AV1 cross-platform decoder, open-source, and focused on speed and correctness
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.4.0
$(PKG)_CHECKSUM := ac8f8ff581906c8ef6479370cf6c1465f282fd2e7cfc2c6366c772f84ad9d30e
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.xz
$(PKG)_URL      := https://downloads.videolan.org/pub/videolan/$(PKG)/$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     := cc meson-wrapper $(BUILD)~nasm

define $(PKG)_BUILD
    '$(TARGET)-meson' \
        -Denable_tools=false \
        -Denable_examples=false \
        -Denable_tests=false \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    $(MXE_NINJA) -C '$(BUILD_DIR)' -j '$(JOBS)' install
endef

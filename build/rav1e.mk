PKG             := rav1e
$(PKG)_WEBSITE  := https://github.com/xiph/rav1e
$(PKG)_DESCR    := The fastest and safest AV1 encoder
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.7.1
$(PKG)_CHECKSUM := da7ae0df2b608e539de5d443c096e109442cdfa6c5e9b4014361211cf61d030c
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_GH_CONF  := xiph/rav1e/tags,v
$(PKG)_DEPS     := cc rust $(BUILD)~nasm cargo-c

define $(PKG)_BUILD
    # Enable networking while we build rav1e
    $(eval export MXE_ENABLE_NETWORK := 1)

    # Uncomment to build/install rav1e binary
    #$(TARGET)-cargo install --no-track --path='$(SOURCE_DIR)' --root='$(PREFIX)/$(TARGET)'
    cd '$(SOURCE_DIR)' && $(TARGET)-cargo cinstall \
        --release \
        --no-default-features \
        --features=asm,threading \
        --prefix='$(PREFIX)/$(TARGET)' \
        --target='$(PROCESSOR)-pc-windows-gnullvm' \
        --target-dir='$(BUILD_DIR)' \
        --library-type=$(if $(BUILD_STATIC),staticlib,cdylib) \
        --dlltool='$(TARGET)-dlltool'

    # Windows convention: import library is called "librav1e.dll.a"
    # https://github.com/lu-zero/cargo-c/issues/280
    $(if $(BUILD_SHARED),
        mv -fv '$(PREFIX)/$(TARGET)/lib/rav1e.dll.a' '$(PREFIX)/$(TARGET)/lib/librav1e.dll.a')
endef

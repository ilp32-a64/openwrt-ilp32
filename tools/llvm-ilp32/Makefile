#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# clang for compiling AArch64 ILP32 target packages (CONFIG_CLANG_ILP32, include/clang-ilp32.mk): the
# llvm-project release with the llvm-ilp32 patches (https://github.com/ilp32-a64/llvm-ilp32), as llvm-bpf.
# AArch64 and clang only: lld has no AArch64 ILP32, GNU ld of the toolchain links, LTO goes through LLVMgold.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=llvm-project
PKG_VERSION:=22.1.8

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).src.tar.xz
PKG_SOURCE_URL:=https://github.com/llvm/llvm-project/releases/download/llvmorg-$(PKG_VERSION)
PKG_HASH:=922f1817a0df7b1489272d18134ee0087a8b068828f87ac63b9861b1a9965888
PKG_CPE_ID:=cpe:/a:llvm:llvm

# its own directory: the tarball unpacks as llvm-project-<version>.src, as the one of llvm-bpf
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/llvm-ilp32/$(PKG_NAME)-$(PKG_VERSION).src

CMAKE_BINARY_SUBDIR := build
CMAKE_SOURCE_SUBDIR := llvm

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/cmake.mk

# plugin-api.h for LLVMgold; the interface is versioned, any binutils release fits the ld of the toolchain
LLVM_ILP32_BINUTILS:=binutils-2.44

define Download/binutils
  URL:=@GNU/binutils/
  FILE:=$(LLVM_ILP32_BINUTILS).tar.xz
  HASH:=ce2017e059d63e67ddb9240e9d4ec49c2893605035cd60e92ad53177f4377237
endef
$(eval $(call Download,binutils))

ifneq ($(HOST_OS),Linux)
  HOST_CFLAGS := $(filter-out -I$(STAGING_DIR_HOST)/include,$(HOST_CFLAGS))
  HOST_CXXFLAGS := $(filter-out -I$(STAGING_DIR_HOST)/include,$(HOST_CXXFLAGS))
endif

LLVM_ILP32_PREFIX = llvm-ilp32-$(PKG_VERSION).$(HOST_OS)-$(HOST_ARCH)
LLVM_ILP32_TRIPLE = aarch64-openwrt-linux-musl_ilp32

CMAKE_HOST_INSTALL_PREFIX = $(STAGING_DIR_HOST)/$(LLVM_ILP32_PREFIX)

# libstdc++ and libgcc linked statically: the prebuilt runs on hosts with an older libstdc++
HOST_LDFLAGS += -static-libstdc++ -static-libgcc

CMAKE_HOST_OPTIONS += \
	-DLLVM_TARGETS_TO_BUILD=AArch64 \
	-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_ILP32_TRIPLE) \
	-DLLVM_ENABLE_PROJECTS=clang \
	-DLLVM_BINUTILS_INCDIR=$(HOST_BUILD_DIR)/binutils-include \
	-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
	-DLLVM_LINK_LLVM_DYLIB=ON \
	-DLLVM_ENABLE_ASSERTIONS=OFF \
	-DLLVM_TOOLCHAIN_TOOLS="llvm-objcopy;llvm-objdump;llvm-readobj;llvm-readelf;llvm-strip;llvm-ar;llvm-as;llvm-dis;llvm-link;llvm-nm;llvm-ranlib;llvm-profdata;llc;opt" \
	-DLLVM_INCLUDE_BENCHMARKS=OFF \
	-DLLVM_INCLUDE_DOCS=OFF \
	-DLLVM_INCLUDE_EXAMPLES=OFF \
	-DLLVM_INCLUDE_TESTS=OFF \
	-DLLVM_ENABLE_BINDINGS=OFF \
	-DLLVM_ENABLE_CURL=OFF \
	-DLLVM_ENABLE_HTTPLIB=OFF \
	-DLLVM_ENABLE_IDE=OFF \
	-DLLVM_ENABLE_LIBEDIT=OFF \
	-DLLVM_ENABLE_LIBPFM=OFF \
	-DLLVM_ENABLE_LIBXML2=OFF \
	-DLLVM_ENABLE_OCAMLDOC=OFF \
	-DLLVM_ENABLE_Z3_SOLVER=OFF \
	-DLLVM_ENABLE_ZLIB=OFF \
	-DLLVM_ENABLE_ZSTD=OFF \
	-DLLVM_PARALLEL_LINK_JOBS=1 \
	-DCMAKE_SKIP_RPATH=OFF

define Host/Prepare
	$(Host/Prepare/Default)
	mkdir -p $(HOST_BUILD_DIR)/binutils-include
	xzcat $(DL_DIR)/$(LLVM_ILP32_BINUTILS).tar.xz | \
		tar -xO -f - $(LLVM_ILP32_BINUTILS)/include/plugin-api.h > $(HOST_BUILD_DIR)/binutils-include/plugin-api.h
endef

# the ILP32 defaults; the paths of the GCC toolchain (--gcc-toolchain, --sysroot) come from clang-ilp32.mk
define Host/Install
	rm -rf $(STAGING_DIR_HOST)/llvm-ilp32*
	$(Host/Install/Default)
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/build/lib/LLVMgold.so $(CMAKE_HOST_INSTALL_PREFIX)/lib/
	cp ./files/$(LLVM_ILP32_TRIPLE).cfg $(CMAKE_HOST_INSTALL_PREFIX)/bin/
	ln -sf clang $(CMAKE_HOST_INSTALL_PREFIX)/bin/$(LLVM_ILP32_TRIPLE)-clang
	ln -sf clang $(CMAKE_HOST_INSTALL_PREFIX)/bin/$(LLVM_ILP32_TRIPLE)-clang++
	ln -s $(LLVM_ILP32_PREFIX) $(STAGING_DIR_HOST)/llvm-ilp32
	STRIP_KMOD= PATCHELF= STRIP=strip $(SCRIPT_DIR)/rstrip.sh $(STAGING_DIR_HOST)/llvm-ilp32
	echo "$(PKG_VERSION)" > $(CMAKE_HOST_INSTALL_PREFIX)/.llvm-version
endef

define Host/Uninstall
	rm -rf $(STAGING_DIR_HOST)/llvm-ilp32*
endef

$(eval $(call HostBuild))

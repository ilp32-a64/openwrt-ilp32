# SPDX-License-Identifier: GPL-2.0-only
#
# Compile the target part of a package with clang (llvm-ilp32: LLVM with the AArch64 ILP32 patches) instead of
# GCC, as selected in Toolchain Options (CONFIG_CLANG_ILP32*). Included by package.mk, after hardening.mk.
# The GCC toolchain stays the sysroot: musl headers and libraries, libgcc, libstdc++ and GNU ld. The target
# comes from the name of the $(REAL_GNU_TARGET_NAME)-clang link of llvm-ilp32, the static defaults
# (--rtlib=libgcc, -ffp-contract=off, ...) from the clang configuration file next to it.
# Host builds, kernel modules and boot loaders are not affected.

# tools/llvm-ilp32, or the prebuilt llvm-ilp32 tarball of a release unpacked as llvm-ilp32/ in the top directory
CLANG_ILP32_DIR ?= $(if $(CONFIG_CLANG_ILP32_PREBUILT),$(TOPDIR)/llvm-ilp32,$(STAGING_DIR_HOST)/llvm-ilp32)

# always GCC: the kernel and its modules, boot loaders and firmware, the toolchain's own libraries
CLANG_ILP32_FIXED_GCC := toolchain
CLANG_ILP32_FIXED_GCC_DIRS := $(TOPDIR)/package/boot/% $(TOPDIR)/package/kernel/% $(TOPDIR)/package/firmware/%

clang_ilp32_list = $(call qstrip,$(CONFIG_CLANG_ILP32_$(1)))

ifneq ($(filter $(PKG_NAME),$(CLANG_ILP32_FIXED_GCC) $(call clang_ilp32_list,GCC_PACKAGES))$(filter $(CLANG_ILP32_FIXED_GCC_DIRS),$(CURDIR)),)
  CLANG_ILP32_USE :=
else ifdef CONFIG_CLANG_ILP32_ALL
  CLANG_ILP32_USE := y
else
  CLANG_ILP32_USE := $(if $(filter $(PKG_NAME),$(call clang_ilp32_list,PACKAGES)),y)
endif

ifeq ($(CLANG_ILP32_USE),y)
  TARGET_CC_NOCACHE := $(CLANG_ILP32_DIR)/bin/$(REAL_GNU_TARGET_NAME)-clang
  TARGET_CXX_NOCACHE := $(CLANG_ILP32_DIR)/bin/$(REAL_GNU_TARGET_NAME)-clang++
  TARGET_CC := $(if $(CONFIG_CCACHE),ccache )$(TARGET_CC_NOCACHE)
  TARGET_CXX := $(if $(CONFIG_CCACHE),ccache )$(TARGET_CXX_NOCACHE)

  # GCC-only options; -specs=hardened-ld-pie.specs: clang links PIE by default
  TARGET_CFLAGS := $(filter-out -fno-caller-saves -fhonour-copts -fanalyzer,$(TARGET_CFLAGS))
  TARGET_LDFLAGS := $(filter-out -specs=%,$(TARGET_LDFLAGS))
  # linker options in CFLAGS (max-page-size, relro, now) make clang warn on every compile-only step, which
  # -Werror turns into errors: move them to LDFLAGS
  CLANG_ILP32_WL := $(filter -Wl$(comma)%,$(TARGET_CFLAGS))
  TARGET_CFLAGS := $(filter-out -Wl$(comma)%,$(TARGET_CFLAGS)) -Qunused-arguments
  # GCC's -z<keyword> linker shorthand (-znow, -zrelro, -zmax-page-size=...) is unknown to clang
  TARGET_LDFLAGS := $(patsubst -z%,-Wl$(comma)-z$(comma)%,$(TARGET_LDFLAGS))
  TARGET_LDFLAGS += $(filter-out $(TARGET_LDFLAGS),$(CLANG_ILP32_WL))
  # LTO (-flto=auto: full LTO in clang) goes through the LLVMgold plugin of GNU ld without asking
  TARGET_LDFLAGS := $(filter-out -fuse-linker-plugin,$(TARGET_LDFLAGS))
  # OpenWrt's fortify-headers use the GCC-only __builtin_va_arg_pack
  TARGET_CPPFLAGS := $(filter-out -I$(TOOLCHAIN_DIR)/include/fortify,$(TARGET_CPPFLAGS))
  # the GCC toolchain of this build (the clang configuration file cannot know where it is); OpenWrt's GCC adds
  # the staging directory to the search paths itself, clang does not
  CLANG_ILP32_TOOLCHAIN := --gcc-toolchain=$(TOOLCHAIN_DIR) --sysroot=$(TOOLCHAIN_DIR)
  TARGET_CFLAGS += $(CLANG_ILP32_TOOLCHAIN) -idirafter $(STAGING_DIR)/usr/include
  TARGET_LDFLAGS += $(CLANG_ILP32_TOOLCHAIN) -L$(STAGING_DIR)/usr/lib -L$(STAGING_DIR)/lib 	-Wl,-rpath-link,$(STAGING_DIR)/usr/lib
endif

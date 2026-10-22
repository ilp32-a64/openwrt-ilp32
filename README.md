# OpenWrt with AArch64 ILP32

[OpenWrt](https://openwrt.org/) 25.12 with an AArch64 ILP32 user land (32-bit `long` and pointers on a
64-bit kernel): musl 1.2.5 with the `aarch64_ilp32` port and an ILP32 Linux kernel. Less memory for every
process, while keeping the AArch64 instruction set, on cores that no longer run 32-bit Arm code.

This default branch only holds this file. OpenWrt is in the branch below.

## Branches

| Branch | Base | Status |
|---|---|---|
| `ilp32-25.12` | OpenWrt 25.12.6 (`v25.12.6`), kernel 6.12.114 | current |

## Enable it

```
make menuconfig
# Advanced configuration options (for developers) → Toolchain Options →
#   AArch64 user-land ABI = ilp32          (CONFIG_AARCH64_ABI_ILP32)
```

- Toolchain: `aarch64-openwrt-linux-musl_ilp32`, GCC 14.3.0 `--with-abi=ilp32`, musl 1.2.5 with the
  `aarch64_ilp32` port (`toolchain/musl/patches/910`–`914`, from
  [ilp32-a64/musl-ilp32](https://github.com/ilp32-a64/musl-ilp32)). musl only; glibc is not supported.
- Packages get an `_ilp32` architecture suffix (e.g. `aarch64_generic_ilp32`), so ILP32 and LP64 packages
  never mix.
- Kernel: `target/linux/generic/hack-6.12/370-*`, the 46 commits of
  [ilp32-a64/linux-ilp32](https://github.com/ilp32-a64/linux-ilp32) branch `ilp32-6.12.y`. The ILP32 ABI
  selects `ARM64_ILP32` and `COMPAT_32BIT_TIME`, and the build stops if either is lost from the kernel
  configuration. AArch32 user land is off. Pointer authentication, BTI and SVE can stay on (armsr/armv8
  enables them).
- Only user space is ILP32: the kernel, TF-A, U-Boot and GRUB are built LP64.

## Targets

| Target | Status |
|---|---|
| `armsr/armv8` | built and tested in QEMU |
| `mediatek/filogic` (OpenWrt One) | builds; not booted on hardware yet |
| others | not tested; only the generic, mediatek and armsr kernel patches are refreshed for 6.12.114 |

## Testing

[ilp32-a64/test-ilp32](https://github.com/ilp32-a64/test-ilp32) (`openwrt/`) boots the armsr/armv8 ILP32
image in QEMU and checks boot, the ILP32 dynamic linker, ubus and the procd services, WAN by DHCP and LAN,
firewall4, uci, time, the musl and system call tests, and that nothing crashes. With Cortex-A53 and with
`-cpu max` (pointer authentication, BTI, SVE): 23/23 checks pass, and 22/22 with every time32 and stat64
system call blocked by seccomp for the whole system.

## License

OpenWrt is GPL-2.0-only, see `COPYING` and `LICENSES/` in the `ilp32-25.12` branch.

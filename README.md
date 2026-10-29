# OpenWrt with AArch64 ILP32

[OpenWrt](https://openwrt.org/) 25.12 with an AArch64 ILP32 user land (32-bit `long` and pointers on a
64-bit kernel): musl 1.2.5 with the `aarch64_ilp32` port and an ILP32 Linux kernel. Less memory for every
process, while keeping the AArch64 instruction set, on cores that no longer run 32-bit Arm code.

Routing, netfilter and Wi-Fi run in the kernel, which stays LP64, so forwarding is not affected. Only the
programs (fw4, LuCI, dnsmasq, hostapd, ...) are ILP32.

Images: [Releases](https://github.com/ilp32-a64/openwrt-ilp32/releases) (pre-releases, experimental).
Discussion: [Discussions](https://github.com/ilp32-a64/openwrt-ilp32/discussions).

## Measured on hardware

OpenWrt One (MediaTek MT7981, Cortex-A53, 1 GB), the same image contents for all three builds, with a
150,000-domain adblock list in dnsmasq, LuCI and a Python process; median of 3 runs, each after a fresh
boot. "ILP32 clang": ucode, lucihttp, ucode-mod-html and json-c compiled with clang (see below), everything
else with GCC 14.3.

| | LP64 | ILP32 (GCC) | ILP32 (clang) |
|---|---:|---:|---:|
| User space memory (PSS, all processes) | 38.3 MB | 28.9 MB (-25%) | 28.9 MB (-25%) |
| Anonymous memory (heap, stacks) | 30.3 MB | 20.9 MB (-31%) | 20.9 MB (-31%) |
| Free memory (MemAvailable) | 863–868 MB | 872–875 MB | 872–877 MB |
| fw4 reload | 2.58 s | 2.84 s | 2.63 s |
| LuCI, 20 page loads | 1.73 s | 1.81 s | 1.76 s |
| dnsmasq restart until the 150,000-domain list answers | 2.96 s | 3.03 s | 3.03 s |
| python3, 100,000-entry dict | 0.38 s | 0.42 s | 0.42 s |

- The savings are in the programs and grow with their data; the kernel does not get smaller. On a 1 GB
  device that is about 9 MB; it matters most on 128–256 MB devices.
- Configuration work (fw4, LuCI) is 2–10% slower with GCC, and only while settings are applied. With the
  hot packages compiled by clang, fw4 is within 2% of LP64.
- In QEMU (armsr, 256 MB) the same workload gives -26% user space memory and 9.6 MB more free memory.
- Method and scripts: [test-ilp32](https://github.com/ilp32-a64/test-ilp32) (`openwrt/`).

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
- Packages get an `_ilp32` architecture suffix (e.g. `aarch64_cortex-a53_ilp32`), so ILP32 and LP64
  packages never mix.
- Kernel: `target/linux/generic/hack-6.12/370-*`, the 46 commits of
  [ilp32-a64/linux-ilp32](https://github.com/ilp32-a64/linux-ilp32) branch `ilp32-6.12.y`. The ILP32 ABI
  selects `ARM64_ILP32` and `COMPAT_32BIT_TIME`, and the build stops if either is lost from the kernel
  configuration. AArch32 user land is off. Pointer authentication, BTI and SVE can stay on (armsr/armv8
  enables them).
- Only user space is ILP32: the kernel, TF-A, U-Boot and GRUB are built LP64.

## Compile packages with clang (optional)

```
# Toolchain Options →
#   [*] Compile target packages with clang (ILP32)          (CONFIG_CLANG_ILP32)
#         Packages to compile with clang: All target packages / Selected packages
#   (ucode lucihttp json-c) Packages compiled with clang      (source package names)
#   ( ) Packages always compiled with GCC
#   [ ] Use prebuilt clang (do not build LLVM)
```

- clang 22.1.8 with the AArch64 ILP32 patches of [ilp32-a64/llvm-ilp32](https://github.com/ilp32-a64/llvm-ilp32),
  built by OpenWrt itself (`tools/llvm-ilp32`, like `llvm-bpf`; about 40 minutes on 2 cores).
- The GCC toolchain stays: musl, libgcc, libstdc++ and GNU ld. Both compilers make the same ABI, so
  packages of both mix freely. The kernel, kernel modules, boot loaders and host tools always use GCC.
- The release images compile ucode, lucihttp, ucode-mod-html and json-c with clang (from v25.12.6-ilp32.3).
- python3 with clang, measured on the OpenWrt One (9 benchmarks): 12–13% faster than with GCC, with the
  same memory. It is not in the release images.
- Compiling every package with clang is possible, but not tested.

## Official LP64 packages: apk-lp64

There is no OpenWrt-ILP32 package repository. The kernel also runs LP64 programs, so `apk-lp64` installs
packages of the official OpenWrt release (e.g. `aarch64_cortex-a53`) into `/opt/lp64`, with its own apk
database, and runs them through the LP64 musl loader:

```
apk-lp64 add tcpdump htop iperf3
tcpdump -i br-lan            # /opt/lp64/usr/bin is at the end of PATH
apk-lp64 purge               # remove everything again
```

The ILP32 system, its apk database and `/etc/apk` are not changed. Command-line programs work; services
of LP64 packages (init scripts, uci configuration, LuCI apps) are not set up. It is in the release images
from v25.12.6-ilp32.3.

## Targets

| Target | Status |
|---|---|
| `armsr/armv8` | release images; tested in QEMU |
| `mediatek/filogic` | release images for 9 popular devices (13 profiles); **OpenWrt One tested on hardware**: boot, Ethernet, 2.4/5 GHz Wi-Fi, LuCI, sysupgrade |
| `bcm27xx/bcm2710` (Raspberry Pi 3) | release images; **Pi 3 B+ tested on hardware**: boot, Ethernet, Wi-Fi, LuCI (factory flashing and sysupgrade not tested) |
| `bcm27xx/bcm2711`, `bcm2712` (Raspberry Pi 4, 5) | release images; not tested on hardware |
| others | not tested; only the generic, mediatek, bcm27xx and armsr kernel patches are refreshed for 6.12.114 |

## Testing

[ilp32-a64/test-ilp32](https://github.com/ilp32-a64/test-ilp32) (`openwrt/`) boots the armsr/armv8 ILP32
image in QEMU and checks boot, the ILP32 dynamic linker, ubus and the procd services, WAN by DHCP and LAN,
firewall4, uci, time, the musl and system call tests, and that nothing crashes. With Cortex-A53 and with
`-cpu max` (pointer authentication, BTI, SVE): 23/23 checks pass, and 22/22 with every time32 and stat64
system call blocked by seccomp for the whole system. Every release runs these checks in GitHub Actions.

On the OpenWrt One, the ucode test suite (178/179; the one failure is a musl regex limitation, not ILP32),
39 LuCI ubus methods and 44 LuCI admin pages were checked as well.

## License

OpenWrt is GPL-2.0-only, see `COPYING` and `LICENSES/` in the `ilp32-25.12` branch.

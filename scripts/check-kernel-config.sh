#!/bin/sh
# Check that the kernel options enabled with CONFIG_KERNEL_* in the OpenWrt configuration are set in the
# resolved kernel configuration. Kconfig turns an option off without a word when its dependencies are not
# met (e.g. ARM64_ILP32 with ARM64_PTR_AUTH), and the kernel is then built without it.
#
# Every CONFIG_KERNEL_<option>=y|m that is not set in the kernel gets a warning: many are on by default
# and harmlessly off (e.g. the ACL options of file systems that are not built). The required options given
# on the command line fail the check.
#
# Usage: check-kernel-config.sh <OpenWrt .config> <resolved kernel .config> [<required option>...]
#        (options without CONFIG_, e.g. ARM64_ILP32)
# Exits with 1 if a required option is lost.

[ $# -ge 2 ] || { echo "usage: $0 <OpenWrt .config> <kernel .config> [<required option>...]" >&2; exit 2; }
owrt=$1; kernel=$2; shift 2
required=" $* "

lost=$(awk '
	FNR == NR {
		if ($0 ~ /^CONFIG_[A-Za-z0-9_]+=[ym]$/)
			set[substr($0, 8, index($0, "=") - 8)] = 1
		next
	}
	/^CONFIG_KERNEL_[A-Za-z0-9_]+=[ym]$/ {
		name = substr($0, 15, index($0, "=") - 15)
		if (!(name in set))
			print name
	}' "$kernel" "$owrt")

rc=0
for o in $lost; do
	case "$required" in
	*" $o "*)
		echo "ERROR: CONFIG_KERNEL_$o is enabled, but CONFIG_$o is not set in the kernel configuration" >&2
		echo "       (its dependencies are not met; check the target kernel configuration)" >&2
		rc=1 ;;
	*)
		echo "WARNING: CONFIG_KERNEL_$o is enabled, but CONFIG_$o is not set in the kernel configuration" >&2 ;;
	esac
done
exit $rc

#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=apk-lp64
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=liviyifan <344781483+liviyifan@users.noreply.github.com>

include $(INCLUDE_DIR)/package.mk

define Package/apk-lp64
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Install and run official OpenWrt LP64 packages on OpenWrt-ILP32
  DEPENDS:=@AARCH64_ABI_ILP32 +apk
  PKGARCH:=all
endef

define Package/apk-lp64/description
 apk-lp64 installs packages of the official OpenWrt release (LP64, e.g. aarch64_cortex-a53) into a root of
 their own (/opt/lp64) and runs them through the LP64 musl loader. The ILP32 system, its apk database and
 its /etc/apk are not changed. Services of LP64 packages are not started.
endef

define Build/Compile
endef

# the official apk key of the OpenWrt release the LP64 packages come from (keyring.git apk/openwrt-25.12.pem);
# it is only copied into the LP64 root, never into /etc/apk/keys
define Package/apk-lp64/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/profile.d $(1)/usr/share/apk-lp64/keys
	$(INSTALL_BIN) ./files/apk-lp64 $(1)/usr/sbin/apk-lp64
	$(INSTALL_DATA) ./files/apk-lp64.profile $(1)/etc/profile.d/apk-lp64.sh
	$(INSTALL_DATA) ./files/openwrt-25.12.pem $(1)/usr/share/apk-lp64/keys/openwrt-25.12.pem
endef

$(eval $(call BuildPackage,apk-lp64))

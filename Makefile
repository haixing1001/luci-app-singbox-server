# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for sing-box server
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+sing-box +luci-base +rpcd +uci +ucode

PKG_NAME:=luci-app-singbox-server
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

define Package/luci-app-singbox-server/conffiles
/etc/config/singbox_server
/etc/singbox-server/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

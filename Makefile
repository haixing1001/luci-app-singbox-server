# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2024 OpenWrt.org

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for standalone sing-box server
LUCI_DEPENDS:= +ucode-mod-fs +ucode-mod-uci
LUCI_NAME:=luci-app-singbox-server
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

LUCI_CONFFILES:=\
	/etc/config/singbox-server \
	/etc/singbox-server/certs/

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(LUCI_NAME)))

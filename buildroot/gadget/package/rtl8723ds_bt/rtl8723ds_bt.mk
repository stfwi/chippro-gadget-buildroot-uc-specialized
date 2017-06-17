################################################################################
#
# rtl8723ds_bt UART Bluetooth Config and Firmware
#
################################################################################

RTL8723DS_BT_VERSION = v3.10_20170117_8723DS_BTCOEX_20161108-1010

RTL8723DS_BT_SITE = https://github.com/NextThingCo/rtl8723ds_bt
RTL8723DS_BT_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(RTL8723DS_BT_SOURCE)

define RTL8723DS_BT_BUILD_CMDS
	$(MAKE) -C $(@D)/rtk_hciattach CC="$(TARGET_CC)"
endef

define RTL8723DS_BT_INSTALL_INIT_SYSV
    $(INSTALL) -m 0755 -D $(RTL8723DS_BT_PKGDIR)/S60rtk_hciattach \
		$(TARGET_DIR)/etc/init.d/S60rtk_hciattach
    $(INSTALL) -m 0755 -D $(RTL8723DS_BT_PKGDIR)/bt_reset \
		$(TARGET_DIR)/sbin/bt_reset
endef

define RTL8723DS_BT_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/rtk_hciattach/rtk_hciattach $(TARGET_DIR)/sbin/rtk_hciattach
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/lib/firmware/rtlbt
	$(MAKE) -C $(@D)/8723D FW_DIR=$(TARGET_DIR)/lib/firmware/rtlbt
endef

$(eval $(generic-package))

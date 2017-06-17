################################################################################
#
# dtc-overlay
#
################################################################################

TARGET_DTC_OVERLAY_VERSION = 61bbb7e7719959dc70917ae855398d278afa99c7
TARGET_DTC_OVERLAY_SITE = $(call github,nextthingco,dtc,$(DTC_OVERLAY_VERSION))
TARGET_DTC_OVERLAY_LICENSE = GPLv2+/BSD-2c
TARGET_DTC_OVERLAY_LICENSE_FILES = README.license GPL
TARGET_DTC_OVERLAY_DEPENDENCIES = host-bison host-flex
HOST_TARGET_DTC_OVERLAY_DEPENDENCIES = host-bison host-flex

#####

define TARGET_DTC_OVERLAY_POST_INSTALL_TARGET_RM_DTDIFF
	rm -f $(TARGET_DIR)/usr/bin/dtdiff
endef

TARGET_DTC_OVERLAY_INSTALL_GOAL = install
ifeq ($(BR2_PACKAGE_BASH),)
TARGET_DTC_OVERLAY_POST_INSTALL_TARGET_HOOKS += TARGET_DTC_OVERLAY_POST_INSTALL_TARGET_RM_DTDIFF
endif

define TARGET_DTC_OVERLAY_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) PREFIX=/usr
endef

# For staging, only the library is needed
define TARGET_DTC_OVERLAY_INSTALL_STAGING_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) PREFIX=/usr install-lib install-includes
endef

define TARGET_DTC_OVERLAY_INSTALL_TARGET_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) PREFIX=/usr $(TARGET_DTC_OVERLAY_INSTALL_GOAL)
endef

# host build
define HOST_TARGET_DTC_OVERLAY_BUILD_CMDS
	$(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D) PREFIX=$(HOST_DIR)/usr
endef

define HOST_TARGET_DTC_OVERLAY_INSTALL_CMDS
	$(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D) PREFIX=$(HOST_DIR)/usr install-bin
endef

$(eval $(generic-package))
$(eval $(host-generic-package))

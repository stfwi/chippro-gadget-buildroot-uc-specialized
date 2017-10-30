################################################################################
#
# duktape-cc CLI binary (/usr/bin/djs)
#
################################################################################

DUKTAPE_CC_VERSION = testing
DUKTAPE_CC_SITE = $(call github,stfwi,duktape-cc,$(DUKTAPE_CC_VERSION))
DUKTAPE_CC_LICENSE = MIT

#####

define DUKTAPE_CC_BUILD_CMDS
	rm -f $(TARGET_DIR)/usr/bin/djs
	rm -f $(STAGING_DIR)/usr/bin/djs
	$(MAKE) -C $(@D) binary CXX=$(TARGET_CXX) STRIP=$(TARGET_STRIP) FLAGS=$(CXXFLAGS)
endef

define DUKTAPE_CC_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/cli/djs $(STAGING_DIR)/usr/bin/djs
endef

define DUKTAPE_CC_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/cli/djs $(TARGET_DIR)/usr/bin/djs
endef

$(eval $(generic-package))

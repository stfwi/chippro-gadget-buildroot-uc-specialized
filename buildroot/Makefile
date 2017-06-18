.PHONY: all nconfig help config-help busybox-nconfig
TOP=$(CURDIR)
OUTPUT_DIR=/opt/output
BR_DIR?=/opt/buildroot
export BR2_EXTERNAL=$(CURDIR)/gadget

all:
	@make -C $(BR_DIR) O=$(OUTPUT_DIR)

%_defconfig:
	@make -C $(BR_DIR) O=$(OUTPUT_DIR) $@

%:
	@make -C $(BR_DIR) O=$(OUTPUT_DIR) $@

nconfig:
	@make -C $(BR_DIR) O=$(OUTPUT_DIR) nconfig

# Busybox has apparently no nconfig but menuconfig
busybox-nconfig:
	@make -C $(BR_DIR) O=$(OUTPUT_DIR) busybox-menuconfig

.PHONY: all nconfig help config-help
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

config-help:
	$(foreach b, $(sort $(notdir $(wildcard $(BR2_EXTERNAL)/configs/*_defconfig))), \
	  printf "  %-29s - Build for %s\\n" $(b) $(b:_defconfig=);)

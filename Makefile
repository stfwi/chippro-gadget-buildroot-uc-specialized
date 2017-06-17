#
# Relay make file for building CHIPpro in a Docker container
# using buildroot (gadgetos).
#
.PHONY: help all clean nconfig linux-nconfig images install docker-init docker-clear busybox-nconfig uboot-nconfig linux-menuconfig uboot-menuconfig busybox-menuconfig menuconfig login-shell bash sh reset rebuild source

help:
	@echo "Usage: make [ help | images | install | nconfig | make linux-nconfig | init-docker | login-shell ]"
	@echo " - help		: Show this help."
	@echo " - images	: Build the current configuration."
	@echo " - install	: Flash the C.H.I.P (pro) target using sunxi-fel."
	@echo " - reset	        : Reset completely to scratch with chippro_defconfig (make distclean chippro_defconfig)."
	@echo " - rebuild	: Alias of 'make reset images'."
	@echo " - nconfig	: Configure buildroot."
	@echo " - linux-nconfig	: Configure Kernel."
	@echo " - docker-init	: Create docker containers (must be done once)."
	@echo " - docker-clear	: Deletes the docker containers."
	@echo " - login-shell	: Log into the docker container using bash."

all: docker-init rebuild

# Docker
docker-init:	; @./scripts/docker-do --init && ./scripts/docker-do make chippro_defconfig
docker-clear:	; @./scripts/docker-do --clear

# Make targets in container
clean:		; @./scripts/docker-do make clean >/dev/null 2>&1 || /bin/true
distclean:	; @./scripts/docker-do make distclean >/dev/null 2>&1 || /bin/true
reset: distclean; @./scripts/docker-do make chippro_defconfig
nconfig:	; @./scripts/docker-do make nconfig
linux-nconfig:	; @./scripts/docker-do make linux-nconfig
busybox-nconfig:; @./scripts/docker-do make busybox-nconfig
uboot-nconfig:	; @./scripts/docker-do make uboot-nconfig
bash:		; @./scripts/docker-do bash
%:		; @./scripts/docker-do make $@

# Download sources
source:		; @./scripts/docker-do make source

# Most important reconfigure options of buildroot
linux-reconfigure: ; @./scripts/docker-do make linux-reconfigure
busybox-reconfigure: ; @./scripts/docker-do make busybox-reconfigure

# Build output images, make them writable on the host, also save important build config files.
images:
	@./scripts/docker-do make
	@./scripts/docker-do mkdir -p /opt/output/images/config || true
	@./scripts/docker-do cp -f /opt/output/.config /opt/output/images/config/buildroot.config
	@./scripts/docker-do cp -f /opt/output/build/linux-ntc-stable-4.4.y/.config /opt/output/images/config/linux.config
	@./scripts/docker-do cp -f /opt/output/build/busybox-1.25.1/.config /opt/output/images/config/busybox.config
	@./scripts/docker-do cp -f /opt/output/build/uboot-ww_2016.01_next/.config /opt/output/images/config/uboot.config
	@./scripts/docker-do chown -R 1000:1000 /opt/output/images

rebuild: reset images

# (Host run, NOT in container) transfer of output images to CHIPpro target.
install:
	@./buildroot/gadget//chippro/scripts/flash.sh buildroot/output --bootloader

# Buildroot aliases for Make shell auto-completion etc
login-shell: bash
sh: bash

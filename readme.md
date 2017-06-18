# CHIPpro `gadget-buildroot` specialisation with focus on dynamic hardware configuration

---
Forked from: @NextThingCo [gadget-buildroot](https://github.com/NextThingCo/gadget-buildroot).
---

This repository is a fork of the @NextThingCo [gadget-buildroot linux build](https://github.com/NextThingCo/gadget-buildroot),
optimised for the "experimental-micro-controller-like-use-case".

(Before reading further, if you like to skip the feature-and-explanation-blabla and see build
 logs and usage examples, [look at these logs here](logs/).)

Briefly the following features are picked to be important:

  - *(Main focus): Device tree configurable without the need to recompile on a host
    PC/Mac*. Especially when working with experimental setups on breadboards, when
    testing sensors, port extensions, connections to micro controllers and the like,
    it is a pain to recompile everything via buildroot. I like to configure the device
    e.g. with scripts during the boot process. The kernel allows device tree overlays
    via the `configfs`, and the DTC with overlay can also be compiled for the target.
    In combination with some C macro replacements it is possible to directly use the
    overlay source to change the hardware configuration (see below).

  - Small system size
  - Fast boot
  - Use of GR8 integrated hardware GPIOs, PWM channels, SPI, I2C, USART, and ADC.
  - Use of the onboard Wifi/Bluetooth module,
  - Kernel drivers for additional GPIO based communication: OneWire, I2C, SPI,

  - USB serial gadget on the USB slave port (and not the Ethernet gadget). A  login shell
    (115200n81, `ttyGS0`) is configured. The serial port on UART1 is still enabled
    as login and boot console (`ttyS0`).

  - Networking, basic inet security: iptables, ip6tables, ip tools, SSH, webserver (civetweb).

  - Kernel preemption (PREEMPT, note this is *not* PREEMPT_RT),

  - Everything else "overboard": no video and audio, nor mouse/keyboard (no alsa,
    display driver, no USB mouse/keyboard HDI).

To understand gadget-os, the CHIPpro, the build, and where which configuration had to be made,
I had to strip down the original NTC sources, reconfigure, patch, add post build steps etc:

  - The build process is controlled via Makefile on the host system. The make commands/targets
    are passed to the Docker environment, where Buildroot make processes are triggered
    accordingly. Some special host make targets are to initialise the Docker environment or
    delete it:

      - `make docker-init`: Initialise the build system platform in a Docker container.
      - `make images`: Trigger a complete build of the CHIPpro target system for flashing.
      - `make install`: Flash the images using `sunxi-fel` (that must be the only thing
         installed on your *host* system except Docker.
      - `make clean`: Invokes buildroot clean in the Docker container
      - `make docker-clear`: Deletes the docker containers (images, system prune etc -
         complete cleanup).
      - `make nconfig`: Buildroot ncurses based menu config.
      - `make linux-nconfig`: Kernel ncurses based menu config.
      - `make busybox-nconfig`: Busybox ncurses based menu config.
      - `make whatever`: Invoke make whatever in the Docker container.
      - `make sh` or `make login-shell`: Bash in the Docker container.

  - Edited the dockerfile and the docker invocation script, so that the docker
    containers/images have different names than the normal gadget-os (prevent
    collisions).

  - Removed the CHIP configs and resources (only CHIPpro needed).

  - Removed all ("br-external") packages except `mtd-utils`, `dtc`, and `rtl8723.*`.
    Init script see below.

  - Added a *target* package of the device tree compiler with overlay.

  - Changed Kernel config: *Removed* all modules and features that are likely not required,
    such as drivers for PCI cards. *Enabled* iptables in the netfilter, more IPv6 support
    stuff, IPsec, drivers for I2C/SPI/OneWire/UART/SMBus connected devices, SCHED_DEADLINE,
    etc (see file linux.config).

  - The initialisation of the basic system is condensed down to one script "/etc/init.d/S00init-system".
    It sets the hostname, loads kernel modules in "/etc/modules", mounts the file systems
    (proc, debug, config, all block devices, initialises `mdev` hotplug and starts the
    gadget for USB serial port connections. `/etc/inittab` opens a `getty` with respawn
    on UART1 (ttyS0), not a root shell without login.

  - /etc/profile with colors and basic aliases like `ll`, `reset`, `su` (uses `su -l`,
    so that the /etc/profile is executed on `su`).

  - Added basic tool packages like `ip`, `ip(6)tables`, `tree`, `xz`

  - Added hostapd/dnsmasq (*not configured yet*, for access point on `wlan1`), blacklisted
    `wlan1` in connmand (connman and hostapd are no friends).

  - Added `/usr/sbin/usb-serial-gadget-getty` for the USB serial port,

  - Added *`/usr/sbin/chippro`*, which is a tool script for CHIPpro specific tasks.
    It currently allows to configure PWM1/2, show the complete pinout of the CHIPpro,
    compile device tree sources using the DTC, dump information about the current driver/
    sysfs device stati, and print what GPIO number in the sysfs e.g. "PB3" has. So it's a
    configuration helper.

  - Additionally you can create a directory `custom` in the base/root directory of this
    repository, which is ignored in GIT. If this directory exists the `docker-do` script
    will mount it as a volume in the Docker environment. So you can add packages to the
    build without having to modify the .gitignore or this repository itself (convenient
    when pulling).


## Quick build instruction

```bash
# Assuming Linux as build host and the repo was cloned into `~/chippro`.

~/chippro$ make docker-init
Initialising docker containers ...
Sending build context to Docker daemon 3.695 GB
Step 1/6 : FROM ubuntu:16.04
16.04: Pulling from library/ubuntu
bd97b43c27e3: Pulling fs layer
[...]
Removing intermediate container cd85fb6c01f7
Successfully built eae00515eb11
uchippro-build-ccache
uchippro-build-output
uchippro-build-dlcache
~/chippro$
#
# Build ...
#
~/chippro$ make images
make[1]: Entering directory '/opt/buildroot'
mkdir -p /opt/output/build/buildroot-config/lxdialog
PKG_CONFIG_PATH="" make CC="/usr/bin/gcc" HOSTCC="/usr/bin/gcc" \
    obj=/opt/output/build/buildroot-config -C support/kconfig -f Makefile.br conf
make[2]: Entering directory '/opt/buildroot/support/kconfig'
/usr/bin/gcc -DCURSES_LOC="<ncurses.h>" -DLOCALE  -I/opt/output/build/buildroot-config -DCONFIG_=\"\"  -MM *.c > /opt/output/build/buildroot-config/.depend 2>/dev/null || :
[...]
[15min later ...]
[...]
Image Name:   Flash CHIP Pro
Created:      Wed Jun 14 18:42:36 2017
Image Type:   ARM Linux Script (uncompressed)
Data Size:    424 Bytes = 0.41 kB = 0.00 MB
Load Address: 00000000
Entry Point:  00000000
Contents:
   Image 0: 416 Bytes = 0.41 kB = 0.00 MB
make[1]: Leaving directory '/opt/buildroot'
~/chippro$

#
# Install on target ...
#
# - sudo apt-get install sunxi-tools
# - unplug CHIPpro and re-plug (to the PC USB port) while pressing the flash mode button
# - then ...
~/chippro$ make install
Loading config: buildroot/output/../gadget//chippro/configs/nand/Toshiba-SLC-4G-TC58NVG2S0H.config
SPL: spl-40000-1000-100.bin
erasing 'spl'...
[...]
resuming boot...
OKAY [  0.000s]
finished. total time: 0.000s

#
# Test via USB gadget connection
#
~/chippro$ dmesg
[...]
[  798.047552] usb 3-9: new high-speed USB device number 4 using xhci_hcd
[  798.176574] usb 3-9: New USB device found, idVendor=1d6b, idProduct=0104
[  798.176581] usb 3-9: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[  798.176585] usb 3-9: Product: USB serial term
[  798.176588] usb 3-9: Manufacturer: NTC
[  798.176590] usb 3-9: SerialNumber: 0123456789
[  798.200675] cdc_acm 3-9:1.0: ttyACM0: USB ACM device
[  798.200932] usbcore: registered new interface driver cdc_acm
[  798.200934] cdc_acm: USB Abstract Control Model driver for USB modems and ISDN adapters
[...]

# Don't ask me why I did choose "cos" for test hostname, user, pass, and root pass. "sin" would
# have done, too.
~/chippro$ screen /dev/ttyACM0 115200n81
cos login: cos
Password: (==cos)
cos@cos:~$ su
Password: (==cos)
root@cos:~# uname -a
Linux cos 4.4.66 #1 SMP PREEMPT Wed Jun 14 18:40:20 UTC 2017 armv7l GNU/Linux
root@cos:~# cat /etc/os-release
NAME=Buildroot
VERSION=2016.11
ID=buildroot
VERSION_ID=2016.11
PRETTY_NAME="Buildroot 2016.11"
root@cos:~# dmesg
[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Initializing cgroup subsys cpuset
[    0.000000] Initializing cgroup subsys cpu
[    0.000000] Initializing cgroup subsys cpuacct
[    0.000000] Linux version 4.4.66 (root@ae6c89f1d3d7) (gcc version 5.3.1 20160412 (Linaro GCC 5.3-2016.05) ) #1 SMP PREEMPT Wed Jun 14 18:40:20 UTC 2017
[    0.000000] CPU: ARMv7 Processor [413fc082] revision 2 (ARMv7), cr=10c5387d
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] Machine model: NextThing Crumb
[    0.000000] cma: Reserved 64 MiB at 0x4c000000
[    0.000000] Memory policy: Data cache writeback
[    0.000000] On node 0 totalpages: 65536
[    0.000000] free_area_init_node: node 0, pgdat c055b200, node_mem_map cbd99000
[    0.000000]   Normal zone: 576 pages used for memmap
[    0.000000]   Normal zone: 0 pages reserved
[    0.000000]   Normal zone: 65536 pages, LIFO batch:15
[    0.000000] CPU: All CPU(s) started in SVC mode.
[    0.000000] PERCPU: Embedded 11 pages/cpu @cbd6f000 s14656 r8192 d22208 u45056
[    0.000000] pcpu-alloc: s14656 r8192 d22208 u45056 alloc=11*4096
[    0.000000] pcpu-alloc: [0] 0
[    0.000000] Built 1 zonelists in Zone order, mobility grouping on.  Total pages: 64960
[    0.000000] Kernel command line: root=ubi0:rootfs rootfstype=ubifs rw ubi.mtd=4 lpj=5009408 ubi.fm_autoconvert=1 quiet
[    0.000000] PID hash table entries: 1024 (order: 0, 4096 bytes)
[    0.000000] Dentry cache hash table entries: 32768 (order: 5, 131072 bytes)
[    0.000000] Inode-cache hash table entries: 16384 (order: 4, 65536 bytes)
[    0.000000] Memory: 187992K/262144K available (3704K kernel code, 281K rwdata, 1240K rodata, 260K init, 240K bss, 8616K reserved, 65536K cma-reserved, 0K highmem)
[    0.000000] Virtual kernel memory layout:
                   vector  : 0xffff0000 - 0xffff1000   (   4 kB)
                   fixmap  : 0xffc00000 - 0xfff00000   (3072 kB)
                   vmalloc : 0xd0800000 - 0xff800000   ( 752 MB)
                   lowmem  : 0xc0000000 - 0xd0000000   ( 256 MB)
                   pkmap   : 0xbfe00000 - 0xc0000000   (   2 MB)
                   modules : 0xbf000000 - 0xbfe00000   (  14 MB)
                     .text : 0xc0008000 - 0xc04dc614   (4946 kB)
                     .init : 0xc04dd000 - 0xc051e000   ( 260 kB)
                     .data : 0xc051e000 - 0xc0564578   ( 282 kB)
                      .bss : 0xc0567000 - 0xc05a3218   ( 241 kB)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] Preemptible hierarchical RCU implementation.
[    0.000000] 	Build-time adjustment of leaf fanout to 32.
[    0.000000] 	RCU restricting CPUs from NR_CPUS=16 to nr_cpu_ids=1.
[    0.000000] RCU: Adjusting geometry for rcu_fanout_leaf=32, nr_cpu_ids=1
[    0.000000] NR_IRQS:16 nr_irqs:16 16
[    0.000000] clocksource: timer: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 79635851949 ns
[    0.000000] clocksource: timer: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 6370868154 ns
[    0.000000] sched_clock: 32 bits at 100 Hz, resolution 10000000ns, wraps every 21474836475000000ns
[    0.000000] Console: colour dummy device 80x30
[    0.000000] console [tty0] enabled
[    0.000000] Calibrating delay loop (skipped) preset value.. 1001.88 BogoMIPS (lpj=5009408)
[    0.000000] pid_max: default: 32768 minimum: 301
[    0.000000] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.000000] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.000000] Initializing cgroup subsys io
[    0.000000] Initializing cgroup subsys memory
[    0.000000] Initializing cgroup subsys devices
[    0.000000] Initializing cgroup subsys freezer
[    0.000000] Initializing cgroup subsys net_cls
[    0.000000] Initializing cgroup subsys perf_event
[    0.000000] Initializing cgroup subsys net_prio
[    0.000000] Initializing cgroup subsys pids
[    0.000000] CPU: Testing write buffer coherency: ok
[    0.000000] CPU0: thread -1, cpu 0, socket -1, mpidr 0
[    0.000000] Setting up static identity map for 0x40008280 - 0x400082d8
[    0.060000] Brought up 1 CPUs
[    0.060000] SMP: Total of 1 processors activated (1001.88 BogoMIPS).
[    0.060000] CPU: All CPU(s) started in SVC mode.
[    0.060000] devtmpfs: initialized
[    0.070000] VFP support v0.3: implementor 41 architecture 3 part 30 variant c rev 3
[    0.070000] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.070000] futex hash table entries: 256 (order: 2, 16384 bytes)
[    0.080000] pinctrl core: initialized pinctrl subsystem
[    0.080000] NET: Registered protocol family 16
[    0.080000] DMA: preallocated 256 KiB pool for atomic coherent allocations
[    0.110000] cpuidle: using governor ladder
[    0.140000] cpuidle: using governor menu
[    0.140000] No ATAGs?
[    0.140000] hw-breakpoint: debug architecture 0x4 unsupported.
[    0.200000] clocksource: Switched to clocksource timer
[    0.210000] NET: Registered protocol family 2
[    0.210000] TCP established hash table entries: 2048 (order: 1, 8192 bytes)
[    0.210000] TCP bind hash table entries: 2048 (order: 2, 16384 bytes)
[    0.210000] TCP: Hash tables configured (established 2048 bind 2048)
[    0.210000] UDP hash table entries: 256 (order: 1, 8192 bytes)
[    0.210000] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes)
[    0.220000] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 253)
[    0.220000] io scheduler noop registered
[    0.220000] io scheduler deadline registered
[    0.220000] io scheduler cfq registered (default)
[    0.220000] gr8-pinctrl 1c20800.pinctrl: initialized sunXi PIO driver
[    0.240000] coupled-voltage-regulator wifi_reg: Couldn't get regulator vin0
[    0.310000] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
[    0.330000] 1c28400.serial: ttyS0 at MMIO 0x1c28400 (irq = 29, base_baud = 1500000) is a U6_16550A
[    0.340000] console [ttyS0] enabled
[    0.360000] 1c28800.serial: ttyS1 at MMIO 0x1c28800 (irq = 30, base_baud = 1500000) is a U6_16550A
[    0.390000] 1c28c00.serial: ttyS2 at MMIO 0x1c28c00 (irq = 31, base_baud = 1500000) is a U6_16550A
[    0.390000] STMicroelectronics ASC driver initialized
[    0.390000] nand: device found, Manufacturer ID: 0x98, Chip ID: 0xdc
[    0.390000] nand: Toshiba TC58NVG2S0H 4G 3.3V 8-bit
[    0.390000] nand: 512 MiB, SLC, erase size: 256 KiB, page size: 4096, OOB size: 256
[    0.390000] Bad block table found at page 131008, version 0x01
[    0.390000] Bad block table found at page 130944, version 0x01
[    0.390000] nand_read_bbt: bad block at 0x000017840000
[    0.390000] nand_read_bbt: bad block at 0x000018000000
[    0.390000] nand_read_bbt: bad block at 0x000018040000
[    0.390000] nand_read_bbt: bad block at 0x00001fec0000
[    0.390000] nand_read_bbt: bad block at 0x00001ff40000
[    0.390000] 5 ofpart partitions found on MTD device 1c03000.nand
[    0.390000] Creating 5 MTD partitions on "1c03000.nand":
[    0.390000] 0x000000000000-0x000000400000 : "SPL"
[    0.400000] 0x000000400000-0x000000800000 : "SPL.backup"
[    0.410000] 0x000000800000-0x000000c00000 : "U-Boot"
[    0.430000] 0x000000c00000-0x000001000000 : "env"
[    0.430000] 0x000001000000-0x000200000000 : "rootfs"
[    0.430000] mtd: partition "rootfs" extends beyond the end of device "1c03000.nand" -- size truncated to 0x1f000000
[    0.430000] libphy: Fixed MDIO Bus: probed
[    0.430000] mousedev: PS/2 mouse device common for all mice
[    0.430000] i2c /dev entries driver
[    0.430000] axp20x 0-0034: AXP20x variant AXP209 found
[    0.440000] axp20x-gpio axp20x-gpio: AXP209 GPIO driver loaded
[    0.450000] input: axp20x-pek as /devices/platform/soc@01c00000/1c2ac00.i2c/i2c-0/0-0034/axp20x-pek/input/input0
[    0.450000] axp20x 0-0034: AXP20X driver loaded
[    0.470000] sunxi-wdt 1c20c90.watchdog: Watchdog enabled (timeout=16 sec, nowayout=0)
[    0.480000] ledtrig-cpu: registered to indicate activity on CPUs
[    0.480000] ip_tables: (C) 2000-2006 Netfilter Core Team
[    0.480000] ThumbEE CPU extension supported.
[    0.480000] Registering SWP/SWPB emulation handler
[    0.500000] sunxi-mmc 1c0f000.mmc: No vqmmc regulator found
[    0.500000] sunxi-mmc 1c0f000.mmc: allocated mmc-pwrseq
[    0.540000] sunxi-mmc 1c0f000.mmc: base:0xd08f6000 irq:20
[    0.540000] ubi0: default fastmap pool size: 95
[    0.540000] ubi0: default fastmap WL pool size: 47
[    0.540000] ubi0: attaching mtd4
[    0.540000] sunxi-mmc 1c0f000.mmc: smc 0 err, cmd 8, RTO !!
[    0.550000] sunxi-mmc 1c0f000.mmc: card claims to support voltages below defined range
[    0.560000] mmc0: new high speed SDIO card at address 0001
[    0.720000] random: nonblocking pool is initialized
[    2.260000] ubi0: scanning is finished
[    2.270000] ubi0 warning: print_rsvd_warning: cannot reserve enough PEBs for bad PEB handling, reserved 30, need 32
[    2.270000] ubi0: attached mtd4 (name "rootfs", size 496 MiB)
[    2.270000] ubi0: PEB size: 262144 bytes (256 KiB), LEB size: 258048 bytes
[    2.270000] ubi0: min./max. I/O unit sizes: 4096/4096, sub-page size 1024
[    2.270000] ubi0: VID header offset: 1024 (aligned 1024), data offset: 4096
[    2.270000] ubi0: good PEBs: 1976, bad PEBs: 8, corrupted PEBs: 0
[    2.270000] ubi0: user volume: 4, internal volumes: 1, max. volumes count: 128
[    2.270000] ubi0: max/mean erase counter: 2/0, WL threshold: 4096, image sequence number: 1529129251
[    2.270000] ubi0: available PEBs: 0, total reserved PEBs: 1976, PEBs reserved for bad PEB handling: 30
[    2.270000] of_cfs_init
[    2.270000] of_cfs_init: OK
[    2.280000] ubi0: background thread "ubi_bgt0d" started, PID 45
[    2.280000] vcc3v0: disabling
[    2.280000] vcc3v3: disabling
[    2.280000] vcc5v0: disabling
[    2.400000] UBIFS (ubi0:3): recovery needed
[    2.830000] UBIFS (ubi0:3): recovery completed
[    2.830000] UBIFS (ubi0:3): UBIFS: mounted UBI device 0, volume 3, name "rootfs"
[    2.830000] UBIFS (ubi0:3): LEB size: 258048 bytes (252 KiB), min./max. I/O unit sizes: 4096 bytes/4096 bytes
[    2.830000] UBIFS (ubi0:3): FS size: 490291200 bytes (467 MiB, 1900 LEBs), journal size 9420800 bytes (8 MiB, 37 LEBs)
[    2.830000] UBIFS (ubi0:3): reserved for root: 0 bytes (0 KiB)
[    2.830000] UBIFS (ubi0:3): media format: w4/r0 (latest is w4/r0), UUID 2B45173A-09B6-4924-8096-D819364EE438, small LPT model
[    2.830000] VFS: Mounted root (ubifs filesystem) on device 0:15.
[    2.840000] devtmpfs: mounted
[    2.840000] Freeing unused kernel memory: 260K (c04dd000 - c051e000)
[    3.210000] NET: Registered protocol family 1
[    3.500000] usbcore: registered new interface driver usbfs
[    3.500000] usbcore: registered new interface driver hub
[    3.500000] usbcore: registered new device driver usb
[    3.510000] UBIFS (ubi0:3): background thread "ubifs_bgt0_3" started, PID 46
[    3.560000] usb_phy_generic.0.auto supply vcc not found, using dummy regulator
[    3.560000] musb-hdrc: ConfigData=0xde (UTMI-8, dyn FIFOs, bulk combine, bulk split, HB-ISO Rx, HB-ISO Tx, SoftConn)
[    3.560000] musb-hdrc: MHDRC RTL version 0.0
[    3.560000] musb-hdrc: 11/11 max ep, 5184/8192 memory
[    3.560000] musb-hdrc musb-hdrc.1.auto: MUSB HDRC host driver
[    3.560000] musb-hdrc musb-hdrc.1.auto: new USB bus registered, assigned bus number 1
[    3.560000] usb usb1: New USB device found, idVendor=1d6b, idProduct=0002
[    3.560000] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    3.560000] usb usb1: Product: MUSB HDRC host driver
[    3.560000] usb usb1: Manufacturer: Linux 4.4.66 musb-hcd
[    3.560000] usb usb1: SerialNumber: musb-hdrc.1.auto
[    3.560000] hub 1-0:1.0: USB hub found
[    3.560000] hub 1-0:1.0: 1 port detected
[    4.360000] RTW: module init start
[    4.360000] RTW: rtl8723ds v5.1.1.2_18132.20160706_BTCOEX20160510-0909
[    4.360000] RTW: build time: Jun 14 2017 18:42:14
[    4.360000] RTW: rtl8723ds BT-Coex version = BTCOEX20160510-0909
[    4.390000] eFuse 00000000: 29 81 00 7c e1 88 07 00 a0 04 ed 35 12 c0 a3 d8
[    4.390000] eFuse 00000010: 21 22 22 23 23 23 24 24 23 23 23 f1 ff ff ff ff
[    4.390000] eFuse 00000020: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000030: ff ff ff ff ff ff ff ff ff ff 22 22 22 22 22 22
[    4.390000] eFuse 00000040: 21 21 21 21 21 02 ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000050: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000060: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000070: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000080: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000090: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000000a0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000000b0: ff ff ff ff ff ff ff ff 20 1c 21 00 00 00 ff ff
[    4.390000] eFuse 000000c0: ff 29 20 11 00 00 00 ff 00 ff 11 ff ff ff ff ff
[    4.390000] eFuse 000000d0: 3e 10 01 12 23 ff ff ff 20 04 4c 02 23 d7 21 02
[    4.390000] eFuse 000000e0: 0c 00 22 04 00 08 00 32 ff 21 02 0c 00 22 2a 01
[    4.390000] eFuse 000000f0: 01 00 00 00 00 00 00 00 00 00 00 00 02 00 ff ff
[    4.390000] eFuse 00000100: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[    4.390000] eFuse 00000110: 00 eb 00 6e 01 00 00 00 00 ff a0 2c 36 8a 70 70
[    4.390000] eFuse 00000120: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000130: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000140: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000150: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000160: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000170: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000180: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 00000190: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001a0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001b0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001c0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001d0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001e0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] eFuse 000001f0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
[    4.390000] RTW: hal_com_config_channel_plan chplan:0x20
[    4.590000] RTW: rtw_regsty_chk_target_tx_power_valid return _FALSE for band:0, path:0, rs:0, t:-1
[    4.590000] RTW: rtw_ndev_init(wlan0) if1 mac_addr=a0:2c:36:8a:70:70
[    4.590000] RTW: rtw_ndev_init(wlan1) if2 mac_addr=a2:2c:36:8a:70:70
[    4.590000] RTW: module init ret=0
[    6.080000] configfs-gadget gadget: high-speed config #1: c
[    6.960000] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    6.970000] ehci-platform: EHCI generic platform driver
[    6.970000] ehci-platform 1c14000.usb: EHCI Host Controller
[    6.970000] ehci-platform 1c14000.usb: new USB bus registered, assigned bus number 2
[    6.970000] ehci-platform 1c14000.usb: irq 22, io mem 0x01c14000
[    6.990000] ehci-platform 1c14000.usb: USB 2.0 started, EHCI 1.00
[    6.990000] usb usb2: New USB device found, idVendor=1d6b, idProduct=0002
[    6.990000] usb usb2: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    6.990000] usb usb2: Product: EHCI Host Controller
[    6.990000] usb usb2: Manufacturer: Linux 4.4.66 ehci_hcd
[    6.990000] usb usb2: SerialNumber: 1c14000.usb
[    6.990000] hub 2-0:1.0: USB hub found
[    6.990000] hub 2-0:1.0: 1 port detected
[    7.070000] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    7.080000] ohci-platform: OHCI generic platform driver
[    7.080000] ohci-platform 1c14400.usb: Generic Platform OHCI controller
[    7.080000] ohci-platform 1c14400.usb: new USB bus registered, assigned bus number 3
[    7.080000] ohci-platform 1c14400.usb: irq 23, io mem 0x01c14400
[    7.140000] usb usb3: New USB device found, idVendor=1d6b, idProduct=0001
[    7.140000] usb usb3: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    7.140000] usb usb3: Product: Generic Platform OHCI controller
[    7.140000] usb usb3: Manufacturer: Linux 4.4.66 ohci_hcd
[    7.140000] usb usb3: SerialNumber: 1c14400.usb
[    7.140000] hub 3-0:1.0: USB hub found
[    7.140000] hub 3-0:1.0: 1 port detected
[    8.610000] NET: Registered protocol family 10
[    9.450000] nf_conntrack version 0.5.0 (3965 buckets, 15860 max)
[   10.050000] Bluetooth: Core ver 2.21
[   10.050000] Bluetooth: Starting self testing
[   10.340000] Bluetooth: ECDH test passed in 287231 usecs
[   10.530000] Bluetooth: SMP test passed in 155 usecs
[   10.530000] Bluetooth: Finished self testing
[   10.530000] NET: Registered protocol family 31
[   10.530000] Bluetooth: HCI device and connection manager initialized
[   10.530000] Bluetooth: HCI socket layer initialized
[   10.530000] Bluetooth: L2CAP socket layer initialized
[   10.530000] Bluetooth: SCO socket layer initialized
[   10.580000] Bluetooth: HCI UART driver ver 2.3
[   10.580000] Bluetooth: HCI UART protocol H4 registered
[   10.580000] Bluetooth: HCI UART protocol BCSP registered
[   10.580000] Bluetooth: HCI UART protocol LL registered
[   10.580000] Bluetooth: HCI UART protocol ATH3K registered
[   10.580000] Bluetooth: HCI UART protocol Three-wire (H5) registered
[   10.580000] Bluetooth: HCI UART protocol Intel registered
[   10.580000] Bluetooth: HCI UART protocol BCM registered
[   10.590000] RTW: ADAPTIVITY_VERSION 9.3.3
[   10.590000] RTW: RTW_ADAPTIVITY_EN_ENABLE
[   10.590000] RTW: RTW_ADAPTIVITY_MODE_NORMAL
[   10.590000] RTW: RTW_ADAPTIVITY_DML_DISABLE
[   10.590000] RTW: RTW_ADAPTIVITY_DC_BACKOFF:2
[   11.100000] RTW: wlan0- hw port(0) mac_addr =a0:2c:36:8a:70:70
[   11.100000] RTW: wlan1- hw port(1) mac_addr =a2:2c:36:8a:70:70
[   11.110000] IPv6: ADDRCONF(NETDEV_UP): wlan0: link is not ready
[   11.190000] NET: Registered protocol family 17
[   11.610000] Bluetooth: Non-link packet received in non-active state
[   12.010000] RTW: nolinked power save enter
[   12.390000] RTW: ADAPTIVITY_VERSION 9.3.3
[   12.390000] RTW: RTW_ADAPTIVITY_EN_ENABLE
[   12.390000] RTW: RTW_ADAPTIVITY_MODE_NORMAL
[   12.390000] RTW: RTW_ADAPTIVITY_DML_DISABLE
[   12.390000] RTW: RTW_ADAPTIVITY_DC_BACKOFF:2
[   12.590000] RTW: wlan0- hw port(0) mac_addr =a0:2c:36:8a:70:70
[   12.590000] RTW: wlan1- hw port(1) mac_addr =a2:2c:36:8a:70:70
[   12.590000] RTW: nolinked power save leave
[   12.590000] RTW: rtw_set_802_11_connect(wlan0)  fw_state=0x00000000
[   12.620000] RTW: start auth
[   12.620000] RTW: auth success, start assoc
[   12.630000] RTW: rtw_cfg80211_indicate_connect(wlan0) BSS not found !!
[   12.630000] RTW: assoc success
[   12.630000] IPv6: ADDRCONF(NETDEV_CHANGE): wlan0: link becomes ready
[   12.630000] RTW: recv eapol packet
[   12.640000] RTW: send eapol packet
[   12.650000] RTW: recv eapol packet
[   12.660000] RTW: send eapol packet
[   12.670000] RTW: set pairwise key camid:0, addr:e8:94:f6:ce:cf:09, kid:0, type:AES
[   12.670000] RTW: set group key camid:1, addr:e8:94:f6:ce:cf:09, kid:1, type:TKIP
root@cos:~#

```

## `/usr/sbin/chippro` tool

Currently the tool is a shell script, I might consider transferring that to c++, after
adding some features making it actually worth using ...

```bash

root@cos:~# chippro
Unknown command, say: chippro <command> [<arguments>]

 chippro info
   Shows the pins/pin-config of the chip.

 enter-flashing-mode --force
   - Sets USB FEL flashing mode and reboots.

 pwm0, pwm1
   Enables, disables or sets the value of PWM channels:
   - pwm? enable   : Enables the channel, set value to 0.
   - pwm? disable  : Set value to 0, disables the channel.
   - pwm? value <0 to 100>  : Set duty cycle to <0 to 100>%.

 device-tree-stati
   Shows the (disabled/okay) stati of the devices registered
   in the device-tree.

 make-device-tree-overlay
   Generates a device tree overlay object (*.dtbo) from a source
   file (*.dts) using the device tree compiler (dtc). In the
   kernel sources some preprocessor defines are available, which
   are here replaced by their numbers directly (using sed).

 gpio-of
   Prints the GPIO sysfs number of a given GR8 port or CHIP pin.
   - chippro gpio-of PE1    --> 129


root@cos:~# chippro info

                 ╭─────────────────────────────────────────────>┃53┣ USB0 GND
                 │                     ╭───────────────────────╮┃52┣ USB0 D-
               ┏━┻━┻━┻━┻┳━━━━━━━┳┻━┻━┻━┻━┓                     │┃51┣ USB0 D+
           GND ┫01      ┃|      ┃      45┣ GND                 │┃50┣ USB0 VCC
       VCC-3V3 ┫02      ┃|______┃ PG03 44┣ UART1-TX/EINT3      │┃49┣ USB1 GND
        IPSOUT ┫03      ┗━━━━━━━┛ PG04 43┣ UART1-RX/EINT4      │┃48┣ USB1 D-
        CHG-IN ┫04                PC13 42┣ LRADC               │┃47┣ USB1 D+
         PWRON ┫05                PE00 41┣ SPI2-CS0/CSIPCLK    ╰┃46┣ USB1 GND
           GND ┫06                PE01 40┣ SPI2-CLK/CSIMCLK
       BATTEMP ┫07                PE02 39┣ SPI2-MOSI/CSIHSYNC  ╭┃29┣ VMIC
           BAT ┫08                PE03 38┣ SPI2-MISO/CSIVSYNC  │┃28┣ MICIN2
 SPDIF-DO/PWM0 ┫09 PB02           PE04 37┣ SDC2-D0/CSID0       │┃27┣ MICIN1
   EINT13/PWM1 ┫10 PG13           PE05 36┣ SDC2-D1/CSID1       │┃26┣ AGND
      TWI1-SCK ┫11 PB15           PE06 35┣ SDC2-D2/CSID2       │┃25┣ PB09 I2S-DI
      TWI1-SDA ┫12 PB16           PE07 34┣ SDC2-D3/CSID3       │┃24┣ PB08 I2S-DO
      UART2-TX ┫13 PD02           PE08 33┣ SDC2-CMD/CSID4      │┃23┣ PB07 I2S-LCLK
      UART2-RX ┫14 PD03           PE09 32┣ SDC2-CLK/CSID5      │┃22┣ PB06 I2S-BCLK
     UART2-CTS ┫15 PD04           PE10 31┣ UART1-TX/CSID6      │┃21┣ PB05 I2S-MCLK
     UART2-RTS ┫16 PD05           PE11 30┣ UART1-RX/CSID7      │┃20┣ HPR
               ┗┳━┳━┳━┳━┳━┳━┳━┳━┳━┳━┳━┳━┳┛                     │┃19┣ HPCOM
                │                       ╰──────────────────────╯┃18┣ HPL
                ╰──────────────────────────────────────────────>┃17┣ GND


root@cos:~# chippro pwm0 enable
root@cos:~# chippro pwm1 enable

# PWM1 -->50% duty cycle (average output voltage 3.3V * 50%)
root@cos:~# chippro pwm0 value 50

# Compile device tree overlay to dtbo file (or send it directly to configfs)
root@cos:~# chippro make-device-tree-overlay myhwconfig.dts > myhwconfig.dtbo

```

## ToDo's

  - [ ] Patch for ntc-linux: Disable I2S, HP, SD-card, so that the user
        can choose via overlay if these components are enabled.

  - [ ] Bluetooth serial config for easier initial setup. HCI attach already
        in boot sequence, but need to rtfm about bluez for discovering.

  - [ ] Optional WiFi access point: Hostapd and dnsmasq there, connmand not
        allowed to use wlan1 (for hostapd then), but access point feature not
        configured yet. Maybe connmand tethering might also already do the
        trick --> need rtfm first.

  - [ ] `chippro` tool:

        - [ ] Enable/disable/set GPIO channel not done yet. Mainly useful for
              testing and boot time initialisation of ports and their initial
              values.

        - [ ] ADC - need also to check if the microphone inputs can be used
              as simple low-sample-rate ADCs.

  - [ ] Make buildroot packages out of the tool, so that they can be included
        into the normal gadget-os on demand / if interesting.

  - [ ] Civetweb: Check ipv6 listening.

  - [ ] /dev: The bloody legacy spam ptyxy/ttyxy are still there, some dependency
        conditions re-enable automatically when building (I disabled this with
        nconfig).


## Contribute, credits, feedback channels

Yes, send fixes, patches, pullreqs, comments remarks and annotations.

*Really important to say again*: The really hard work is done in the NTC modules
(ntx-linux, gadget-os, u-boot, etc). This repository is merely a specialised
configuration and application of that. Therfore the license it the same, and
I would be happy to see that some of the specialisations here are usable and
helpful for the community. This repository is intentionally not a github-fork of
[gadget-buildroot](https://github.com/NextThingCo/gadget-buildroot) because I
think there are too many features moved, changed, and removed, making it not
really eligible for pull requests. Interesting for the NTC gadget-os might be
some aspects of this project.

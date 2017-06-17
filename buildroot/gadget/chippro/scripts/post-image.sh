#!/bin/bash

read_config() {
	echo "${1}"
	grep "${1}=" ${BR2_CONFIG} | sed -e 's/^[A-Za-z0-9_]\+=\(.*\)$/\1/'
}

# ROOT_DIR="$(pwd)/../gadget"
ROOT_DIR="${BR2_EXTERNAL_GADGETOS_PATH}"
BOARD_DIR=${ROOT_DIR}//chippro

IMAGE_TYPE="${2}"
if [ -n "${IMAGE_TYPE}" ]; then
	IMAGE_CONFIG_FILE="${BOARD_DIR}/configs/nand/${IMAGE_TYPE}.config"
	echo "Image type: ${IMAGE_TYPE}"

	if [ ! -f "${IMAGE_CONFIG_FILE}" ]; then
		echo -e "Selected NAND type: ${IMAGE_TYPE} but config file does not exist:"
		echo -e "\t${IMAGE_CONFIG_FILE}"
		exit 1
	fi

	echo "Loading config file: ${IMAGE_CONFIG_FILE}"
	source "${IMAGE_CONFIG_FILE}"

	IMG2SIMG=$(which img2simg)
	if [ -z "${IMG2SIMG}" ]; then
		echo -e "ERROR: Please install 'img2simg' using your distribution's package manager."
		echo -e "\tThis is likely located inside of the 'android-tools-fsutils' package"
		exit 1
	else
		echo -e "Writing sparse ubi image for nand type: ${IMAGE_TYPE}"
		echo -e "\terase block size: ${NAND_ERASE_BLOCK_SIZE}"
		${IMG2SIMG} ${BINARIES_DIR}/rootfs.ubi ${BINARIES_DIR}/rootfs.ubi.sparse "${NAND_ERASE_BLOCK_SIZE}"
	fi

	NAND_ERASE_BLOCK_SIZE=${NAND_ERASE_BLOCK_SIZE} NAND_PAGE_SIZE=${NAND_PAGE_SIZE} NAND_OOB_SIZE=${NAND_OOB_SIZE} ${BOARD_DIR}/scripts/chip-create-nand-images.sh "${BASE_DIR}"
else
	echo "No nand type selected. Not generating sparse image"
fi

cat <<-EOF > ${1}/uboot.script.source
	mw \${scriptaddr} 0x0
	sleep 4
	fastboot 0
	setenv boot_kernel 'bootz \${kernel_addr_r} - \${fdt_addr_r}'
	setenv boot_ubi 'run read_kernel; run read_fdt; run boot_kernel'
	setenv bootargs 'root=ubi0:rootfs rootfstype=ubifs rw ubi.mtd=4 lpj=5009408 ubi.fm_autoconvert=1 quiet'
	setenv bootcmd 'run boot_ubi'
	setenv read_fdt 'ubi read \${fdt_addr_r} fdt'
	setenv read_kernel 'ubi read \${kernel_addr_r} kernel'
	ubi part UBI
	boot
EOF

mkimage -A arm -T script -C none -n "Flash CHIP Pro" -d "${1}/uboot.script.source" "${1}/uboot.script"

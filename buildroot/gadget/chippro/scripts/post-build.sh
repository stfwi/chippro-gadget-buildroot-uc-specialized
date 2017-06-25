#!/bin/bash
ROOT_DIR="${BR2_EXTERNAL_GADGETOS_PATH}"
BOARD_DIR=${ROOT_DIR}/chippro
PWD=$(pwd)
MKIMAGE=${HOST_DIR}/usr/bin/mkimage

#
# /usr/sbin/automount
#
echo '- adding /usr/sbin/automount ...'
mkdir -p ${TARGET_DIR}/usr/sbin
cat <<'EOF' > ${TARGET_DIR}/usr/sbin/automount
#!/bin/sh
[ "$1" == "" ] && exit 1
if [ "$(mount | grep $1 | wc -l)" -ge 1 ]; then
  umount "/dev/$1" && rmdir "/media/$1" || exit 1
else
  mkdir -p "/media/$1" && mount -o sync "/dev/$1" "/media/$1" && exit 0
  rmdir "/media/$1"
  exit 1
fi
EOF
chmod 550 ${TARGET_DIR}/usr/sbin/automount
chown root:root ${TARGET_DIR}/usr/sbin/automount

#
# Fix overlay permissions if neeed
#
echo '- fixing permissions for /etc/init.d ...'
chown -R root:root ${TARGET_DIR}/etc/init.d/*
chmod 755 ${TARGET_DIR}/etc/init.d/*
echo '- fixing permissions for overlay added scripts ...'
chown root:root ${TARGET_DIR}/usr/sbin/chippro
chmod 555 ${TARGET_DIR}/usr/sbin/chippro
chown root:root ${TARGET_DIR}/usr/sbin/usb-serial-gadget-getty
chmod 555 ${TARGET_DIR}/usr/sbin/usb-serial-gadget-getty

#
# Relink /var/lock to /var/run (not /tmp)
#
echo '- redirecting /var/lock to /run (not /tmp) ...'
cd ${TARGET_DIR}/var
unlink lock
ln -s ../run lock

#
# Make own tmpfs for /var/log, not just /tmp
#
if test -z "$(cat ${TARGET_DIR}/etc/fstab | grep '/var/log')"; then
  echo '- making tmpfs for /var/log ...'
  echo "tmpfs           /var/log            tmpfs   size=5M,mode=0777,nosuid,nodev  0       0" >> ${TARGET_DIR}/etc/fstab
  unlink ${TARGET_DIR}/var/log
  mkdir -p ${TARGET_DIR}/var/log
  chmod 755 ${TARGET_DIR}/var/log
fi

#
# /etc/modprobe.d/rtl8723ds_mp.conf: Change annoying log level.
#
if [ -f ${TARGET_DIR}/etc/modprobe.d/rtl8723ds_mp.conf ]; then
echo '- reducing log level in /etc/modprobe.d/rtl8723ds_mp.conf ...'
cat <<'EOF' > ${TARGET_DIR}/etc/modprobe.d/rtl8723ds_mp.conf
options 8723ds rtw_drv_log_level=1
#rtw_mp_mode=1
EOF
fi

#
# Remove /etc/init.d/rcS and /etc/init.d/rcK because
# runparts is used in inittab
#
echo '- removing target /etc/init.d/rc* because run-parts is used ...'
rm -f ${TARGET_DIR}/etc/init.d/rc*


cd $PWD
# ${MKIMAGE} -f ${BOARD_DIR}/bootimg.its ${BINARIES_DIR}/bootimg.itb
# cat <<-EOF >> ${TARGET_DIR}/etc/mdev.conf
# sd[a-z][0-9]* 0:0 0660 *(/opt/bin/automount $MDEV)
# mmcblk[0-9]p[0-9] 0:0 0660 *(/opt/bin/automount $MDEV)

echo '- post-build.sh done.'
# EOF

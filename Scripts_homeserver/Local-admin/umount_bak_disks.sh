#!/bin/bash

bak_files_disk_partition=$(lsblk -fl | grep -E "HOMESRV_BAK" | awk '{print $1}')
bak_files_destination="/mnt/backups/files"
bak_os_img_disk_partition=$(lsblk -fl | grep -E "OS_IMG" | awk '{print $1}')
bak_os_img_destination="/mnt/backups/os_img"

if [[ -n $bak_files_disk_partition ]]; then
	sleep 2
	umount $bak_files_destination &>/dev/null
fi

sleep 5

if [[ -n $bak_os_img_disk_partition ]]; then
	sleep 2
	umount $bak_os_img_destination &>/dev/null
fi

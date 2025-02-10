#!/bin/bash

bak_disk=$(lsblk -fl | grep -E "BACKUP_DISK" | awk '{print $1}')
bak_destination="/mnt/backups/bkp_disk"

if [[ -n $bak_disk ]]; then
	sleep 2
	mount /dev/$bak_disk $bak_destination &>/dev/null
else
	sleep 2
	umount $bak_destination &>/dev/null
fi

#!/bin/bash

disk=$(lsblk -fl | grep -E "HOMESRV_BAK" | awk '{print substr($1, 1, 3)}')
external_disk_dir="/mnt/external"

umask 022
for part_num in $(lsblk -fl | grep -E "HOMESRV_BAK" -B 4 | awk 'NR<5{print substr($1, 4)}'); do
	partition="${disk}${part_num}"
	mount_dir_name=$(lsblk -fl | grep -E $partition | sed -e 's/1.0//g' | xargs | awk '{print $3}')
	dir=$external_disk_dir/${mount_dir_name}
	tmp_dir=$(mktemp -d -p $external_disk_dir)
	mv $tmp_dir $dir
	mount /dev/$partition $dir
done

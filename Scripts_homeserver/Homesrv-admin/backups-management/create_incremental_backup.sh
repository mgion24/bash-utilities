#!/bin/bash

#	INFORMACIÓN
#
# Este script solamente se ejecutaría cada sábado de forma automática
# por la tarea cron, ejecutando solo la copia incremental correspondiente
# del bloque <if>. Se pueden crear copias incrementales manualmente al
# ejecutar este script, pero no tendrá salida estándar ya que está pensado para
# ejecutarse de forma automática. Se podrán crear tantas copias incrementales
# como se necesiten en un mes dado, de forma manual por el
# administrador de sistemas de la empresa.
#

# --- VARIABLES --- #

# Directorio de administración y archivo de rutas candidatas a copia de seguridad
management_dir="/root/Scripts/Homesrv-admin/backups-management"
bak_routes_file="${management_dir}/backup_routes.txt"
bak_routes=""

# Bucle para generar una concatenación a 'bak_routes' y ser añadida al comando 'tar'
for BAK_ROUTE in $(/bin/cat $bak_routes_file); do bak_routes+="${BAK_ROUTE} "; done

# Formatos de creación de directorios y comprimidos de backups
date_tgz_format=$(date +"%d-%m-%Y")
date_dir_snap_format=$(date +"%m-%Y")
time_format=$(date +"%H%M%S")

# Rutas de directorios de backups y snapshots
backup_dir="/mnt/backups/files/backups/main_backups"
complete_dir="complete_backups"
snapshot_dir="snapshots"
incremental_dir="incremental_backups"
db_bak_dir="database_backups"
month_dir="${backup_dir}/${date_dir_snap_format}"

# --- EJECUCIÓN --- #

if [ -d $backup_dir ]; then

	if [[ ! -d $month_dir ]]; then
		# Si no existe la carpeta del mes en cuestión, la crea
		mkdir -p $month_dir/{$complete_dir,$snapshot_dir,$incremental_dir,$db_bak_dir} &>/dev/null
	fi

	# En este punto los directorios existen

	# --- VARIABLES DE ARCHIVOS GLOBALES --- #

	# Nombre de archivos de snapshots y copias completas existentes de forma global en el directorio de copias
	last_global_snapshot=$(/bin/ls -v -R $backup_dir | grep -E "snapshot\.([0-9]{2}-[0-9]{4})((_v[0-9]+)|(_d[0-9]+)).snar" | tail -n 1)
	last_global_comp_bak=$(/bin/ls -v -R $backup_dir | grep -E "bak_comp\.([0-9]{2}-[0-9]{2}-[0-9]{4})((_v[0-9]+)|(_d[0-9]+))(_t[0-9]{6}).tgz" | tail -n 1)

	# Versiones existentes de ambos archivos de forma global
	last_global_snapshot_version=$(echo $last_global_snapshot | tr '_' ' ' | tr '.' ' ' | awk '{print $3}')
	last_global_comp_bak_version=$(echo $last_global_comp_bak | tr '_' ' ' | awk '{print $3}')

	# Meses correspondientes a cada archivo de forma global
	last_global_snapshot_month=$(echo $last_global_snapshot | tr '.' ' ' | tr '-' ' ' | awk '{print $2}')
	last_global_comp_bak_month=$(echo $last_global_comp_bak | tr '.' ' ' | tr '-' ' ' | awk '{print $3}')

	# --- VARIABLES DE ARCHIVOS DE MES --- #

	# Nombre de archivos de snapshots y copias completas ya existentes en el directorio del mes
	this_snapshot=$(/bin/ls -v $month_dir/$snapshot_dir | grep -E "snapshot\.([0-9]{2}-[0-9]{4})((_v[0-9]+)|(_d[0-9]+))\.snar" | tail -n 1)
	this_comp_bak=$(/bin/ls -v $month_dir/$complete_dir | grep -E "bak_comp\.([0-9]{2}-[0-9]{2}-[0-9]{4})((_v[0-9]+)|(_d[0-9]+))(_t[0-9]{6})\.tgz" | tail -n 1)

	# Versiones correspondientes de ambos archivos en el directorio del mes
	this_snapshot_version=$(echo $this_snapshot | tr '_' ' ' | tr '.' ' ' | awk '{print $3}')
	this_comp_bak_version=$(echo $this_comp_bak | tr '_' ' ' | awk '{print $3}')

	# Meses correspondientes a cada archivo en el directorio del mes
	this_snapshot_month=$(echo $this_snapshot | tr '.' ' ' | tr '-' ' ' | awk '{print $2}')
	this_comp_bak_month=$(echo $this_comp_bak | tr '.' ' ' | tr '-' ' ' | awk '{print $3}')

	if [[ -n "${this_snapshot}" && -n "${last_global_comp_bak}" ]]; then

		# En este punto existe el archivo de snapshot para este mes y la última copia completa global
		# Se comprobaría si tanto los meses como las versiones coinciden para ambos archivos
		# Se necesita de la última copia completa global, por motivos de correcto funcionamiento
		# y comprobación de versiones.

		if [[ "${this_snapshot_version}" == "${last_global_comp_bak_version}" && "${this_snapshot_month}" == "${last_global_comp_bak_month}" ]]; then

			# Cumpliría las condiciones para que se pueda crear la copia incremental
			bak_inc="bak_inc.${date_tgz_format}_${this_snapshot_version}_t${time_format}.tgz"

			# Se crea la copia incremental
			tar -cpzf $month_dir/$incremental_dir/$bak_inc -g $month_dir/$snapshot_dir/$this_snapshot $bak_routes &>/dev/null

			if [ $? -eq 0 ]; then
				sleep 1
				time_format=$(date +"%H%M%S")
				db_bak="db_bak.${date_tgz_format}_${this_snapshot_version}_t${time_format}.sql.tgz"
				mysqldump --all-databases | gzip > $month_dir/$db_bak_dir/$db_bak
				if [ $? -eq 0 ]; then
					exit 0
				else
					exit 1
				fi
			else
				exit 1
			fi
		fi

	elif [[ -n "${last_global_snapshot}" && -n "${last_global_comp_bak}" ]]; then

		# Si no existen archivos en el directorio del mes, comprueba si existe el último
		# archivo de copia completa y snapshot de forma global
		# Volvería a comprobar si los meses y versiones de dichos archivos coinciden

		if [[ "${last_global_snapshot_version}" == "${last_global_comp_bak_version}" && "${last_global_snapshot_month}" == "${last_global_comp_bak_month}" ]]; then

			# Si todo coincide, se busca la ubicación de la snapshot en '$back_dir' y se trae al directorio '$month_dir/$snapshots'
			last_global_snapshot_location=$(find $backup_dir -type f -name "${last_global_snapshot}" | xargs /bin/ls -v | tail -n 1)
			sleep 10
			cp -np "${last_global_snapshot_location}" "/tmp/"
			if [ $? -ne 0 ]; then
				exit 1
			fi
			sleep 10
			tmp_snapshot=$(find /tmp/ -type f | grep -E "snapshot\.([0-9]{2}-[0-9]{4})((_d[0-9]+)|(_v[0-9]+))\.snar")
			sleep 10
			mv -nf "${tmp_snapshot}" "${month_dir}/${snapshot_dir}"
			if [ $? -ne 0 ]; then
				exit 1
			fi
			# La variable '$this_snapshot' almacena la última snapshot del directorio del mes, por tanto al estar ya copiada
			# la snapshot global, se procede a realizar la copia incremental con esta snapshot
			bak_inc="bak_inc.${date_tgz_format}_${last_global_snapshot_version}_t${time_format}.tgz"
			this_snapshot=$(/bin/ls -v $month_dir/$snapshot_dir | grep -E "snapshot\.([0-9]{2}-[0-9]{4})((_v[0-9]+)|(_d[0-9]+))\.snar" | tail -n 1)

			# Se crea la copia incremental
			tar -cpzf $month_dir/$incremental_dir/$bak_inc -g $month_dir/$snapshot_dir/$this_snapshot $bak_routes &>/dev/null

			if [ $? -eq 0 ]; then
				sleep 1
				time_format=$(date +"%H%M%S")
				db_bak="db_bak.${date_tgz_format}_${last_global_snapshot_version}_t${time_format}.sql.tgz"
				mysqldump --all-databases | gzip > $month_dir/$db_bak_dir/$db_bak
				if [ $? -eq 0 ]; then
					exit 0
				else
					exit 1
				fi
			else
				exit 1
			fi

		else
			# En este punto no habría ninguna copia completa ni snapshot que coincidan en versión y mes
			# ni en el directorio del propio mes ni globalmente, por tanto se sale con código de estado
			# no exitoso
			exit 1
		fi

	else
		# No existen ningún archivo de copias o snapshots en el directorio principal de copias
		# Se sale con código no exitoso
		exit 1
	fi

else
	# Si no existe el directorio de backups, significa que puede haber un error de disco
	# Se sale del script con código no exitoso
	exit 1
fi

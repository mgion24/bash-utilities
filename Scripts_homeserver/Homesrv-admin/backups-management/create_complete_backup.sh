#!/bin/bash

#       INFORMACIÓN
#
# Este script solamente se ejecutaría una vez cada 3 meses de forma automática
# por la tarea cron, y solo se ejecutaría el primer sábado de cada 3 meses
# ejecutando solo la copia correspondiente del bloque <else>.
# Todo el código que existe en el <if-then> se ejecutaría si y sólo si
# se necesite de otra copia completa de los archivos importantes,
# ejecutada de forma manual por el administrador, con las versiones
# de snapshot y backup correspondientes.
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

# Versión por defecto
def_version=1

# Nombre del archivo de backup completo (se sobreescribirá con 'def_version' del bloque <else>)
bak_comp="bak_comp.${date_tgz_format}_d${def_version}_t${time_format}.tgz"

# Nombre del archivo de snapshot (se sobreescribirá con 'def_version' del bloque <else>)
snapshot="snapshot.${date_dir_snap_format}_d${def_version}.snar"

# Nombre del archivo de backup completo de la base de datos
db_bak="db_bak.${date_tgz_format}_d${def_version}_t${time_format}.sql.tgz"

# --- EJECUCIÓN --- #

if [ -d $backup_dir ]; then

	# El directorio principal de copias existe, por tanto el disco está montado

	# Se recogen en variables las últimas snapshots y copias completas creadas previamente o en este mes
	last_global_comp_bak=$(/bin/ls -v -R $backup_dir | grep -E "bak_comp\.([0-9]{2}-[0-9]{2}-[0-9]{4})(_v[0-9]+)(_t[0-9]{6})\.tgz" | tail -n 1)
	last_global_snapshot=$(/bin/ls -v -R $backup_dir | grep -E "snapshot\.([0-9]{2}-[0-9]{4})(_v[0-9]+).snar" | tail -n 1)

	# Se recogen también las versiones y meses tanto de la snapshot como de la copia completa, y se pasan todos los números
	# a Integer

	last_global_comp_bak_version=$(echo $last_global_comp_bak | tr '-' ' ' | tr '_' ' ' | awk '{print $5}' | awk '{print $2}' FS='v')
	last_global_comp_bak_version=$((last_global_comp_bak_version))

	last_global_snapshot_version=$(echo $last_global_snapshot | tr '-' ' ' | tr '_' ' ' | tr '.' ' ' | awk '{print $4}' | awk '{print $2}' FS='v')
	last_global_snapshot_version=$((last_global_snapshot_version))

	last_global_comp_bak_month=$(echo $last_global_comp_bak | tr '-' ' ' | awk '{print $2}')
	last_global_comp_bak_month=$((last_global_comp_bak_month))

	last_global_snapshot_month=$(echo $last_global_snapshot | tr '.' ' ' | tr '-' ' ' | awk '{print $2}')
	last_global_snapshot_month=$((last_global_snapshot_month))

	if [ -d $month_dir ]; then

		# Creación de copias manuales

		# Se guardan en variables si existiese alguna copia o snapshot anterior EN EL MISMO MES, NO DE FORMA GLOBAL

		complete_bak_files=$(/bin/ls $month_dir/$complete_dir/ 2>/dev/null | grep -E "bak_comp\.([0-9]{2}-[0-9]{2}-[0-9]{4})((_d[0-9]+)|(_v[0-9]+))?(_t[0-9]{6})\.tgz")
        	snapshot_files=$(/bin/ls $month_dir/$snapshot_dir/ 2>/dev/null | grep -E "snapshot\.([0-9]{2}-[0-9]{4})((_d[0-9]+)|(_v[0-9]+))?\.snar")

		if [[ -n "${complete_bak_files}" || -n "${snapshot_files}" ]]; then

                	# En este punto existen archivos de backups anteriores, por tanto
                	# se pregunta al usuario si quiere seguir con la copia completa

                	echo -e "\n[!] Ya existen archivos de copias anteriores."
                	echo -ne "[?] ¿Deseas continuar con la creación de otra copia completa?(s/n): "
                	read response

                	while [ "$response" != "s" ] && [ "$response" != "n" ]; do
                        	echo -ne "\n[-] Respuesta no válida, introduce 's' para Si o 'n' para No: "
                        	read response
                	done

			if [[ "$response" == "s" ]]; then

				# En este punto se tiene la respuesta del usuario
				# De forma global se compara la última versión tanto de backup como de snapshot y se escoge la mayor
				last_global_version=$(( last_global_comp_bak_version > last_global_snapshot_version ? last_global_comp_bak_version : last_global_snapshot_version ))

				# Por defecto version = 1, si existe 'last_global_version' entonces se sobreescribe con 'last_global_version + 1'
       	                	version=1

                        	if [ "${last_global_version}" -gt 0 ]; then
                                	# Si la version existe entonces version vale 'last_global_version + 1'
                                	version=$((last_global_version + 1))
                        	fi

				# En este punto se crearán las carpetas con los formatos recogidos
				# por la version de la nueva backup manual

                        	echo -e "\n[+] Realizando copia de seguridad completa versión 'v${version}'...\n"
                        	sleep 1

				# Nuevos formatos de nombre para las copias y las snapshots
                        	new_snapshot="snapshot.${date_dir_snap_format}_v${version}.snar"
                        	new_bak_comp="bak_comp.${date_tgz_format}_v${version}_t${time_format}.tgz"

                        	# En este punto se realiza la copia de seguridad como tal
                        	tar -cpzf $month_dir/$complete_dir/$new_bak_comp -g $month_dir/$snapshot_dir/$new_snapshot $bak_routes &>/dev/null

                        	if [ $? -eq 0 ]; then
                                	echo -e "[+] Copia con versión 'v${version}' completada\n"
                                	sleep 1
					time_format=$(date +"%H%M%S")
					new_db_bak="db_bak.${date_tgz_format}_v${version}_t${time_format}.sql.tgz"
					mysqldump --all-databases | gzip > $month_dir/$db_bak_dir/$new_db_bak
					if [ $? -eq 0 ]; then
						echo -e "[+] Copia completa de las bases de datos con versión 'v${version}' completada\n"
						sleep 1
                                		echo -e "[+] Saliendo...\n"
                                		exit 0
					else
						echo -e "[-] Error en la copia de la base de datos"
                                        	sleep 1
                                        	exit 1
					fi
                        	else
                                	echo -e "[-] Error en la copia de seguridad"
                                	sleep 1
                                	exit 1
                        	fi

			else
				# No se realiza nada y se sale del script
                        	echo -e "\n[+] Saliendo...\n"
                        	exit 0
			fi

		else
			# No existirían ni copias ni snapshots anteriores EN ESTE MES

			echo -e "\n[!] No existen copias de seguridad. Los directorios están vacíos."
                	echo -ne "[?] ¿Deseas crear una copia de seguridad ahora?(s/n): "
                	read response

                	while [ "$response" != "s" ] && [ "$response" != "n" ]; do
                        	echo -ne "\n[-] Respuesta no válida, introduce 's' para Si o 'n' para No: "
                        	read response
                	done

                	if [[ "$response" == "s" ]]; then

				last_global_version=$(( last_global_comp_bak_version > last_global_snapshot_version ? last_global_comp_bak_version : last_global_snapshot_version ))

				version=1

                                if [ "${last_global_version}" -gt 0 ]; then
                                        # Si la version existe entonces version vale 'last_global_version + 1'
                                        version=$((last_global_version + 1))
                                fi

				echo -e "\n[+] Creando nueva copia de seguridad con version 'v${version}' en el directorio ${date_dir_snap_format}...\n"
                        	sleep 1
                        	if [ ! -d $month_dir/$complete_dir ] || [ ! -d $month_dir/$snapshot_dir ] || [ ! -d $month_dir/$incremental_dir ] || [ ! -d $month_dir/$db_bak_dir ]; then
                                	mkdir -p $month_dir/{$complete_dir,$snapshot_dir,$incremental_dir,$db_bak_dir}
                        	fi

				new_snapshot="snapshot.${date_dir_snap_format}_v${version}.snar"
                                new_bak_comp="bak_comp.${date_tgz_format}_v${version}_t${time_format}.tgz"

                        	tar -cpzf $month_dir/$complete_dir/$new_bak_comp -g $month_dir/$snapshot_dir/$new_snapshot $bak_routes &>/dev/null
				if [ $? -eq 0 ]; then
                                        echo -e "[+] Copia con versión 'v${version}' completada\n"
                                        sleep 1
					time_format=$(date +"%H%M%S")
					new_db_bak="db_bak.${date_tgz_format}_v${version}_t${time_format}.sql.tgz"
                                        mysqldump --all-databases | gzip > $month_dir/$db_bak_dir/$new_db_bak
                                        if [ $? -eq 0 ]; then
                                                echo -e "[+] Copia completa de las bases de datos con versión 'v${version}' completada\n"
                                                sleep 1
                                                echo -e "[+] Saliendo...\n"
                                                exit 0
                                        else
                                                echo -e "[-] Error en la copia de la base de datos"
                                                sleep 1
                                                exit 1
                                        fi
                                else
                                        echo -e "[-] Error en la copia de seguridad"
                                        sleep 1
                                        exit 1
                                fi
                	else
                        	# No se realiza nada y se sale del script
                        	echo -e "\n[+] Saliendo...\n"
                        	exit 0
                	fi

		fi

	else

		# Creación de copias automáticas

		# Se recogen las últimas copias por defecto realizadas, se obtiene la versión de cada una de ellas
		# y se determina cuál es la mayor para saber qué número tiene que incrementar en 1
		last_comp_bak_def=$(/bin/ls -v -R $backup_dir | grep -E "bak_comp\.([0-9]{2}-[0-9]{2}-[0-9]{4})(_d[0-9]+)(_t[0-9]{6})\.tgz" | tail -n 1)
		last_snapshot_def=$(/bin/ls -v -R $backup_dir | grep -E "snapshot\.([0-9]{2}-[0-9]{4})(_d[0-9]+).snar" | tail -n 1)

		last_comp_bak_def_version=$(echo $last_comp_bak_def | tr '_' ' ' | awk '{print $3}' | awk '{print $2}' FS='d')
		last_comp_bak_def_version=$((last_comp_bak_def_version))

		last_snapshot_def_version=$(echo $last_snapshot_def | tr '_' ' ' | tr '.' ' ' | awk '{print $3}' | awk '{print $2}' FS='d')
		last_snapshot_def_version=$((last_snapshot_def_version))

		# Se comprueba si el mes actual es el primer múltiplo de 3
		# para reiniciar el contador de versión por defecto.
		if [ $(( $(date +"%-m") )) -eq 3 ]; then
			# Se reinicia el contador
                	last_global_default_version=0
                else
                	# Se comprueba la mayor versión disponible
			last_global_default_version=$(( last_comp_bak_def_version > last_snapshot_def_version ? last_comp_bak_def_version : last_snapshot_def_version ))
                fi

		# Por defecto def_version = 1, y se va a ir incrementando en uno cada vez que se realice una
		# copia de seguridad completa automática
		def_version=$((last_global_default_version + 1))

		# Se redefinen los formatos de backups y snapshots para que puedan tomar la nueva versión automática por defecto
		bak_comp="bak_comp.${date_tgz_format}_d${def_version}_t${time_format}.tgz"
		snapshot="snapshot.${date_dir_snap_format}_d${def_version}.snar"

		mkdir -p $month_dir/{$complete_dir,$snapshot_dir,$incremental_dir,$db_bak_dir} &>/dev/null

		# Se crea la copia de seguridad
		tar -cpzf $month_dir/$complete_dir/$bak_comp -g $month_dir/$snapshot_dir/$snapshot $bak_routes &>/dev/null

        	if [ $? -eq 0 ]; then
			sleep 1
			time_format=$(date +"%H%M%S")
			db_bak="db_bak.${date_tgz_format}_d${def_version}_t${time_format}.sql.tgz"
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

else
	# El disco no estaría montado, habría un error
	exit 1
fi

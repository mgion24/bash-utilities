#!/bin/bash

# --- INFO --- #
# La letra 'c' delante del identificador indica que es un error de copia completa
# La letra 'i' delante del identificador indica que es un error de copia incremental

# --- VARIABLES GLOBALES --- #

# Array global con tipos de identificadores
id_types=("c" "i")

# Variables principales
backup_management_dir="/root/Scripts/Homesrv-admin/backups-management"
backup_dir="/mnt/backups/files/backups/main_backups"
execute="/bin/bash"

# Variables relacionadas con las copias completas
create_complete_backup="${execute} ${backup_management_dir}/create_complete_backup.sh"

# Variables relacionadas con las copias incrementales
create_incremental_backup="${execute} ${backup_management_dir}/create_incremental_backup.sh"

# Variables relacionadas con ejecuciones exitosas
success_email="${backup_management_dir}/templates/success_bak_email_template.html"
gen_success_email="${execute} ${backup_management_dir}/generate_bak_success_email.sh"

# Variables relacionadas con errores
err_dir="/var/log/homeserver/backups"
err_file="err.log"
err_email="${backup_management_dir}/templates/err_bak_email_template.html"
gen_err_email="${execute} ${backup_management_dir}/generate_bak_err_email.sh"

# --- EJECUCIÓN --- #

if [ $(date +"%-m" -d 'last saturday') -ne $(date +"%-m") ] && [[ $(( $(date +"%-m") % 3 )) == 0 ]]; then
# Descomentar para forzar copia completa
# if [ "true" ]; then
	# Si el mes del último sábado no coincide con el mes actual (es el primer sábado del mes) y
	# el mes actual es múltiplo de 3 (Marzo, Junio, Septiembre ó Diciembre), entonces
	# se ejecuta una copia completa
	$create_complete_backup

	if [ $? -eq 0 ]; then
		# Se envía mail de éxito de la copia al administrador
		$gen_success_email
		/usr/sbin/sendmail -t < $success_email
		if [ $? -eq 0 ]; then
			exit 0
		fi
	else
		# Ha ocurrido un error en la copia completa
		err_id=$(date +"err%d%m%Y-%H%M%S")
		echo -e "[!] Error '${id_types[0]}_${err_id}': Hubo algún error creando la copia de seguridad completa" >> $err_dir/$err_file
		$gen_err_email
		/usr/sbin/sendmail -t < $err_email
		if [ $? -eq 0 ]; then
			exit 0
		fi
	fi
else
	# En cualquier otro caso crea una copia incremental
	$create_incremental_backup

	if [ $? -eq 0 ]; then
                # Se envía mail de éxito de la copia al administrador
                $gen_success_email
                /usr/sbin/sendmail -t < $success_email
                if [ $? -eq 0 ]; then
			exit 0
		fi
        else
                # Ha ocurrido un error en la copia incremental
		err_id=$(date +"err%d%m%Y-%H%M%S")
                echo -e "[!] Error '${id_types[1]}_${err_id}': Hubo algún error creando la copia de seguridad incremental" >> $err_dir/$err_file
                $gen_err_email
                /usr/sbin/sendmail -t < $err_email
		if [ $? -eq 0 ]; then
			exit 0
		fi
        fi
fi

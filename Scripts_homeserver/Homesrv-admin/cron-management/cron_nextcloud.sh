#!/bin/bash

# Script que se encarga de la ejecución de 'cron.php' para la aplicación
# de Nextcloud por el usuario 'www-data'. Lo podría ejecutar el usuario
# 'www-data' pero se ha elegido realizarlo de esta forma para que se pueda
# saber, en cierta medida, cuándo se está ejecutando el cron o no, dependiendo
# de si existe un fichero llamado 'is_executed' que tiene un '1' mientras se
# esté ejecutando el 'cron.php' y '0' en cualquier otro caso.

# VARIABLES
cron_job="sudo -u www-data php --define apc.enable_cli=1 -f /var/www/nextcloud/cron.php"
actual_work_dir="/root/Scripts/Homesrv-admin/cron-management"

# '0' si no se ejecuta el cron y '1' mientras se esté ejecutando
is_executed="${actual_work_dir}/is_executed"

# Archivo de registros
log_file="${actual_work_dir}/logs/cron_logs"

# PROCESAMIENTO

# Espera a que MariaDB esté activo
# Se salta el while si la base de datos está activa
while [[ ! $(systemctl is-active mariadb.service) == "active" ]]; do
	sleep 10
done

# EJECUCIÓN

# Coloca un '1' en 'is_executed' y se espera 30 segundos para que el script 'shutdown.sh'
# tenga margen de esperar el tiempo suficiente para poder apagar o reiniciar el servidor.
echo 1 > $is_executed
sleep 30

# Ejecuta la tarea programada
$cron_job
if [ $? -eq 0 ]; then
	# Si el cron se ha ejecutado correctamente se espera otros 30 segundo (para dar
	# margen a que el cron termine por completo) y luego vuelve a colocar '0' en el
	# archivo 'is_executed'.
	sleep 30
	echo 0 > $is_executed
	exit 0
else
	# DEBUG: Si ha ocurido un error en la ejecución de 'cron.php' crea un archivo llamado
	# 'cron_logs' y almacena un registro del estado de 'is_executed', junto con la fecha
	# y hora que se ha producido el evento y el estado de la base de datos en ese instante.
	#echo -e "is_executed: " $(/bin/cat $is_executed)"\t->Fecha-hora: "$(date)"\t->Estado MariaDB: " $(systemctl status mariadb.service) >> $log_file
	echo 0 > $is_executed
	exit 0
fi

# Independientemente de si el script 'cron.php' ha sido exitoso o no
# se saldrá con código exitoso como prevención enviado de emails
# al administrador, por el ligero problema que se tiene. Por ello
# se decide esto. Se mejorará este script en un futuro.
#exit 0

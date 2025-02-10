#!/bin/bash

# Comprueba el estado de la base de datos mariadb
db="mariadb"
db_srv="${db}.service"
db_soc="${db}.socket"
db_logs="/root/Scripts/Homesrv-admin/cron-management/logs/db_logs"

while ! mysqladmin ping &>/dev/null; do
	echo "[-] Se va a esperar a aceptar conexiones." >> $db_logs
	sleep 2
done


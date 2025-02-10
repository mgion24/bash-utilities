#!/bin/bash

# Script que se dedica al apagado o reinicio del servidor
# de forma correcta, apagando los servicios necesarios
# y esperando a que se ejecuten todas las tareas programadas
# necesarias antes de iniciar el apagado o reinicio

# ---- FUNCIONES ---- #
send_email() {
        $generate_email
        /usr/sbin/sendmail -t < $mail_template
}
determine_command(){
        local command=$1
        case $command in
          "p")
               # Se aplica un apagado
               command="/sbin/shutdown -h now"
               echo $command
               ;;
          "r")
               # Se aplica un reinicio
               command="/sbin/shutdown -r now"
               echo $command
               ;;
          *)
             # Comando incorrecto
             exit 1
             ;;
        esac
}

# ---- VARIABLES ---- #
shutdown_dir="/root/Scripts/Homesrv-admin/shutdown-management"
cron_dir="/root/Scripts/Homesrv-admin/cron-management"
is_executed="${cron_dir}/is_executed"
mail_template="${shutdown_dir}/templates/shutdown_email_template.html"
generate_email="/bin/bash ${shutdown_dir}/generate_email.sh"
command=$(determine_command $1)

# ---- EJECUCIÓN ---- #
if [[ -n $(/bin/ls $cron_dir | grep "is_executed") ]]; then
	# El archivo 'is_executed' existe
	# Si existe se comprueba si es '1' (el cronjob se ejecuta) o '0' (el cronjob no se ejecuta)

	if [[ $(/bin/cat $is_executed) == "0" ]]; then
		# Se puede apagar o reiniciar el servidor
		sleep 2
		systemctl stop apache2.service
		if [ $? -eq 0 ]; then
			sleep 5
			$command
		else
			send_email
			exit 1
		fi
	else
		# Se espera hasta que esté a 0, es decir, el cron se haya acabado
		while [[ $(/bin/cat $is_executed) == "1" ]]; do
			sleep 5
		done
		if [[ $(/bin/cat $is_executed) == "0" ]]; then
			# Ya se puede apagar o reiniciar el servidor
			sleep 2

			# Se apaga primero el servidor web, para que todos los scripts 'php'
			# dejen de ejecutarse, luego ejecuta el apagado o reinicio
			# según el parámetro que se haya escogido.
			systemctl stop apache2.service
			if [ $? -eq 0 ]; then
				sleep 5
				$command
			else
				# Envia un email al administrador si no se pudo apagar el servicio web.
				send_email
				exit 1
			fi
		else
			# is_executed sigue estando en '1' después de haberse
			# ejecutado el while, por tanto es un error y envia un
			# email al administrador.
			send_email
			exit 1
		fi
	fi
else
	# El archivo 'is_executed' no existe, se manda un email al administrador
	send_email
	exit 1
fi

#!/usr/bin/env bash

# Utilidad para montar discos cuando el sistema operativo linux no los monta de forma automática, 
# sin necesidad de usar comandos, esta utilidad monta los discos preguntando al usuario
# por los mismos, al igual que sus particiones con su correspondiente FSTYPE. 
#
# Requiere tener instalado batcat, fdisk y fsck
# Para cancelar el script Ctrl + C
# Cambiar las variables según convengan

# Comprueba si es root, sino sale con código no exitoso, usando el EUID de root
if [[ $EUID -ne 0 ]]; then
  echo -e "\n[-] Se requieren privilegios de superusuario"
  exit 1
fi

# Definición de constantes
# Usuario y grupo no privilegiados
USR_NO_PRIV="marian"
GRP_NO_PRIV="marian"

# Establecemos el gestor de archivos por defecto configurado en el sistema operativo
FILES_MANAGER="xdg-open"

echo -e "\n[+] Utilidad para montaje de discos en caso de no reconocerlo de forma automática [+] \n"
echo -e "[!] Cuidado al elegir el disco para montaje [!]\n"
echo -e "[!] Actúa con mucha cautela [!]\n"
sleep 3
echo -e "[+] Se muestran los discos disponibles, elige el disco que necesites montar, obviando el prefijo /dev/ [+]"

# Mostramos discos montados
for disk in $(fdisk -l | grep "Disco" | grep -iv "loop" | awk '{print $2}' | sed 's/://g'); do 
  fdisk -l "$disk" | bat -l java
done

# Leemos el input del usuario
read -p "Disco: /dev/" disco

# Comprueba que se escoja el disco correcto 
while ! lsblk -n -o NAME | grep -E "^$disco$" > /dev/null; do
  echo -e "[!] El disco no existe o no tiene particiones válidas."
  read -p "Disco: /dev/" disco
done

# Guardamos todas las particiones del disco en una cadena
particiones=$(lsblk -f -l -n /dev/$disco | grep -E "(^${disco}[0-9]+\s.*)|(^${disco}p[0-9]+\s.*)")

# Calculamos cuantas particiones tiene con wc -l
cantidad_particiones=$(echo "$particiones" | wc -l)

# Si hay 0 particiones es porque el disco no tiene particiones reconocidas
if [ $cantidad_particiones -eq 0 ]; then
  echo "[!] El disco no tiene particiones reconocidas."
  exit 1
else

  # Se detectan las particiones y se muestran en formato lista
  echo "[+] Se detectaron varias particiones en /dev/$disco:"
  echo "$particiones" | nl

  # Establecemos el rango disponible para elegir la partición
  MIN=$(( $(echo "$particiones" | nl | awk '{print $1}' | head -n 1) ))
  MAX=$(( $(echo "$particiones" | nl | awk '{print $1}' | tail -n 1) ))

  particion_montada=1
  read -p "[?] Selecciona el número de la partición a montar: " seleccion
  
  # Bucle que repite la selección de partición si ésta ha sido previamente montada
  while [ $particion_montada -eq 1 ]; do
    while [ $(( $seleccion )) -lt $MIN -o $(( $seleccion )) -gt $MAX ]; do    # Comprobamos rangos
      echo -e "[!] Partición inválida"
      read -p "[?] Selecciona el número de la partición a montar: " seleccion
    done

    # Recogemos la partición
    particion=$(echo "$particiones" | sed -n "${seleccion}p" | awk '{print $1}')

    # Comprobamos si ha sido previamente montada
    if findmnt -r -n -o TARGET "/dev/$particion" > /dev/null; then
      echo -e "[!] Partición ya montada"
      read -p "[?] Selecciona el número de la partición a montar: " seleccion
      particion_montada=1
    else
      particion_montada=0
    fi
  done
fi

# Preguntamos antes de hacer un checkeo con fsck, ya que puede ser peligroso y corromper
# datos si hay problemas graves en la partición o en el disco
read -p "[?] ¿Quieres hacer un checkeo con fsck antes del montaje? (s/n): " respuesta
if [[ $respuesta =~ ^[Ss]$ ]]; then
    # Aqui la particion no estaría montada. Checkeamos su estado con fsck
    echo -e "[+] Comprobando y checkeando la partición..."
    sleep 1 
    fsck -y "/dev/$particion"
    if [ $? -ne 0 ]; then
      echo -e "[X] Error en el checkeo de la partición. Saliendo..."
      exit 1 
    fi
    echo -e "[+] Checkeo correcto."
fi

# Si se ha checkeado correctamente, recogemos su FSTYPE con lsblk
tipo_particion=$(lsblk -f -l -n "/dev/"$particion | awk '{print $2}')
if [ -z "$tipo_particion" ]; then
    echo "[X] No se pudo detectar el tipo de sistema de archivos. Saliendo..."
    exit 1
fi

# Se comprueba que la partición no esté vacía y que no exista previamente el directorio
if [ -n "$particion" -a ! -d "/mnt/$particion" ]; then
  
  mkdir -p "/mnt/$particion"
  echo -e "[+] Montando la partición..."

  # Montamos la partición con su tipo correcto, el usuario y el grupo
  # en la ruta que hemos indicado. Hay que diferenciar cada tipo de partición
  # para establecer las opciones de montaje correctas

  if [[ $tipo_particion == "vfat" || $tipo_particion == "exfat" || $tipo_particion == "fat32" ]]; then
    mount_opt="uid=$USR_NO_PRIV,gid=$GRP_NO_PRIV,fmask=113,dmask=002"
  elif [[ $tipo_particion == "ntfs" ]]; then
    mount_opt="uid=$USR_NO_PRIV,gid=$GRP_NO_PRIV,umask=002"
  else
    mount_opt="uid=$USR_NO_PRIV,gid=$GRP_NO_PRIV"
  fi

  # Con las opciones definidas solo falta crear el punto de montaje
  mount -t $tipo_particion -o $mount_opt "/dev/$particion" "/mnt/$particion"
  if [ $? -ne 0 ]; then
    echo -e "[X] Error en el montaje. Saliendo..."
    exit 1
  fi

  # Asignamos permisos y propietarios por si el sistema de archivos fuese EXT4
  # ya que para FAT, NTFS y similares, usando la opción umask, fmask o dmask 
  # en el comando mount funciona
  if [[ $tipo_particion == "ext4" || $tipo_particion == "xfs" || $tipo_particion == "btrfs" ]]; then
    echo -e "[+] Asignando permisos..."
    chown -R "$USR_NO_PRIV:$GRP_NO_PRIV" "/mnt/$particion"
    chmod -R 775 "/mnt/$particion"
    if [ $? -ne 0 ]; then
      echo -e "[X] Error en la asignación de permisos. Saliendo..."
      exit 1
    fi
  fi
  echo -e "[+] Partición /dev/$particion montada en /mnt/$particion"
  echo -e "[+] Abriendo Archivos..."

  # Abrimos Archivos con el usuario no privilegiado e independizamos el proceso
  # de la terminal, mandando todo el STDOUT y STDERR al /dev/null y dejando
  # el proceso en segundo plano
  sudo -u "$USR_NO_PRIV" $FILES_MANAGER "/mnt/$particion" &>/dev/null & disown
  echo -e "[+] Presiona cualquier tecla cuando termines."

  # Esperamos a recibir algún input del teclado
  read -n 1 -s
  echo -e "[+] Desmontando partición..."
  sleep 2

  # Desmontamos todo y borramos el directorio que se había creado
  umount "/mnt/$particion"
  if [ $? -ne 0 ]; then
    echo -e "[X] Error al desmontar la partición. Saliendo..."
    exit 1
  fi
  echo -e "[+] Eliminando el directorio '/mnt/$particion'..."
  rmdir "/mnt/$particion"
  if [ $? -ne 0 ]; then
    echo -e "[X] Error al eliminar el directorio '/mnt/$particion'"
    exit 1
  fi
  echo -e "\n[+] Programa finalizado con éxito."
  exit 0
else
  echo "[!] Error. La partición está vacía o ya existe la carpeta. Saliendo..."
  exit 1
fi

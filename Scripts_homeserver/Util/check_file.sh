#!/bin/bash

# Script que permite comprobar si se han modificado los permisos de los archivos
# de una ruta de origen y otra de destino dada.
# Uso principal: comprobar si al hacer una copia de forma manual de algún servicio,
# en este caso Nextcloud, si algunos archivos clave se han visto modificados sus permisos
# para que el admin de sistemas pueda cambiarlos posteriormente
# Se usa en conjunto con el comando find, para que por cada archivo se compruebe con el mismo
# ubicado en otra ruta.

f="$1"
archivo="${f#./}"

err="/root/err.log"

ruta_original="/mnt/nextcloud/"
ruta_copia="/root/next_bkp/"

archivo_original="${ruta_original}${archivo}"
archivo_copia="${ruta_copia}${archivo}"

#perm_arch_original=$(stat "${archivo_original}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $2}' | awk -F '/' '{print $1}' | xargs)
#perm_arch_copia=$(stat "${archivo_copia}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $2}' | awk -F '/' '{print $1}' | xargs)

#uid_arch_original=$(stat "${archivo_original}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $3}' | awk -F '/' '{print $2}' | awk '{print $1}' | xargs)
#uid_arch_copia=$(stat "${archivo_copia}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $3}' | awk -F '/' '{print $2}' | awk '{print $1}' | xargs)

#gid_arch_original=$(stat "${archivo_original}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $4}' | awk -F '/' '{print $2}' | xargs)
#gid_arch_copia=$(stat "${archivo_copia}" | grep "Access: (" | sed -e 's/(//g' -e 's/)//g' | awk -F ':' '{print $4}' | awk -F '/' '{print $2}' | xargs)

# Forma mas eficiente de filtrado de permisos
perm_arch_original=$(stat -c "%a" "$archivo_original")
uid_arch_original=$(stat -c "%u" "$archivo_original")
gid_arch_original=$(stat -c "%g" "$archivo_original")
attr_arch_original=$(lsattr "${archivo_original}" | awk '{print $1}' | xargs)

perm_arch_copia=$(stat -c "%a" "$archivo_copia")
uid_arch_copia=$(stat -c "%u" "$archivo_copia")
gid_arch_copia=$(stat -c "%g" "$archivo_copia")
attr_arch_copia=$(lsattr "${archivo_copia}" | awk '{print $1}' | xargs)


echo -e " -> Procesando archivo: ./${archivo}"

if [ $perm_arch_original -ne $perm_arch_copia ]; then
	echo -e "\n[+] Archivo: ${archivo_original}" >> $err
	echo -e "[-] Los permisos de los archivos '${archivo_original}' y '${archivo_copia}' no son iguales." >> $err
fi

if [ $uid_arch_original -ne $uid_arch_copia ]; then
	echo -e "\n[+] Archivo: ${archivo_original}" >> $err
	echo -e "[-] Los UIDs de los archivos '${archivo_original}' y '${archivo_copia}' no son iguales." >> $err
fi

if [ $gid_arch_original -ne $gid_arch_copia ]; then
	echo -e "\n[+] Archivo: ${archivo_original}" >> $err
	echo -e "[-] Los GIDs de los archivos '${archivo_original}' y '${archivo_copia}' no son iguales." >> $err
fi

if [ "${attr_arch_original}" != "${attr_arch_copia}" ]; then
	echo -e "\n[+] Archivo: ${archivo_original}" >> $err
	echo -e "[-] Los atributos extendidos de los archivos '${archivo_original}' y '${archivo_copia}' no son iguales." >> $err
fi

#echo "Perm arch original: "$perm_arch_original
#echo "Archivo original: "$archivo_original
#echo "Perm arch copia: "$perm_arch_copia
#echo "Archivo copia: "$archivo_copia

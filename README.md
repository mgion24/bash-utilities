# bash-utilities

Repositorio con scripts de Bash que utilizo en mi día a día para administrar servidores y automatizar tareas.

## Scripts disponibles

### `mount_disk.sh`
Script para montar discos en sistemas Linux de forma automática e intuitiva, sin necesidad de usar la terminal manualmente. Permite al usuario seleccionar opciones de montaje fácilmente.

---

## Scripts para gestionar VPN WireGuard
Ubicados en el directorio `vpn-clients_admin`, estos scripts facilitan la creación y administración de clientes VPN en un servidor WireGuard Linux. Son las herramientas que uso en mi entorno autoalojado para gestionar rápidamente el acceso de clientes a la red interna.

Próximamente, compartiré detalles sobre el proyecto **SyncBetter** y su configuración.

---

## Scripts Homeserver
Colección de scripts que uso para administrar mi servidor de manera eficiente.

### `Remote-admin`
Scripts para gestionar el acceso remoto mediante:
- Reglas de iptables
- Apertura/cierre de puertos en el servidor
- Habilitación y deshabilitación de acceso SSH para administración remota en caso de problemas con la VPN

### `Util`
Scripts de utilidades varias.

### `Local-admin`
Scripts para el montaje de discos y particiones en el servidor de manera automatizada.

### `Homesrv-admin`
Scripts generales para la administración del servidor, incluyendo:
- Copias de seguridad con versionado
- Administración de tareas cron de Nextcloud
- Apagado y reinicio controlado del servidor

#### `backups-management`
Directorio clave del repositorio. Contiene scripts para realizar copias de seguridad completas e incrementales utilizando `tar`. Se acompaña de un archivo `.txt` con las rutas críticas que deben incluirse en las copias. No se han empleado otras herramientas como Rsync, BorgBackup..., sino varios scripts en Bash entrelazados, algunos funcionando como controladores que llaman a otros scripts de copias o de generación del email HTML, y otros que procesan y crean la copia en base a un versionado en el nombre específicos, y otros que generan los emails de éxito o error que se envían al administrador.

#### `bitwarden-management`
Script que ejecuta una copia de seguridad de la base de datos MSSQL del contenedor Docker de Bitwarden. Inicialmente, la copia se realizaba desde un script dentro del propio contenedor, con una ejecución programada por defecto a las 2 de la mañana. Para tener más control sobre el proceso, copié ese script a mi sistema local y creé un nuevo punto de montaje, permitiendo que ahora el script local sea el que se pase al contenedor. Gracias a esta modificación, puedo definir el horario de ejecución mediante una tarea cron, asegurando que la copia se realice en el momento que yo decida.

#### `cron-management`
Script que se encarga de ejecutar `cron.php` de Nextcloud, controlando en base a variables y redirecciones si la tarea cron se está ejecutando en ese instante o no.

#### `shutdown-management`
Scripts que garantizan un apagado o reinicio seguro del servidor:
- Se detienen servicios críticos de forma ordenada
- Se verifica que no hayan tareas programadas en ejecución (especialmente en Nextcloud)
- Se ejecuta un apagado limpio para evitar pérdida de datos

---

## Contribuciones
Este repositorio contiene herramientas personalizadas para mi entorno, pero cualquier sugerencia o mejora es bienvenida.

---


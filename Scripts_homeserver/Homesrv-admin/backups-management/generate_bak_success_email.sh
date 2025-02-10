#!/bin/bash

management_dir="/root/Scripts/Homesrv-admin/backups-management"
backup_dir="/mnt/homeserver/backups/main_backups"

last_db_bak=$(/bin/ls -v -R $backup_dir | grep -E "db_bak\.([0-9]{2}-[0-9]{2}-[0-9]{4})((_d[0-9]+)|(_v[0-9]+))(_t[0-9]{6})\.sql\.tgz" | tail -n 1)
db_weight=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_db_bak}" | awk '{print $5}')
db_date=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_db_bak}" | awk '{print $6,$7}')
db_hour=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_db_bak}" | awk '{print $8}')
last_bak=$(/bin/ls -v -R $backup_dir | grep -E "bak_((comp)|(inc))\.([0-9]{2}-[0-9]{2}-[0-9]{4})((_d[0-9]+)|(_v[0-9]+))(_t[0-9]{6})\.tgz" | tail -n 1)
weight=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_bak}" | awk '{print $5}')
date=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_bak}" | awk '{print $6,$7}')
hour=$(/bin/ls -v -l -h -R $backup_dir | grep -E "${last_bak}" | awk '{print $8}')
bak_dir_location=$(dirname $(find $backup_dir -type f -name "${last_bak}"))
db_bak_dir_location=$(dirname $(find $backup_dir -type f -name "${last_db_bak}"))

if [ -n "$(echo "$last_bak" | grep "comp")" ]; then
	bak_type="completa"
else
	bak_type="incremental"
fi

cat > $management_dir/templates/success_bak_email_template.html << EOF
From: Syncbetter IT <admin.syncbetter@gmail.com>
To: Marian <mariangeorgian24@gmail.com>
Subject: Copia de seguridad $bak_type creada con éxito
Content-Type: text/html

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Copia de seguridad $bak_type creada con éxito</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            font-size: 18px;
            line-height: 1.6;
            color: #444;
            margin: 0;
            padding: 0;
	    text-align: justify;
        }

        .email-container {
            max-width: 600px;
            margin: 20px auto;
            padding: 20px;
            border: 1px solid #ccc;
            border-radius: 8px;
        }

        h1 {
            font-family: 'Georgia', serif;
            font-size: 26px;
            color: #333;
            margin-bottom: 20px;
        }

        p {
            margin-bottom: 15px;
        }

        .success-box {
            background-color: #f6f8fa;
            border: 1px solid #d1d5da;
            border-radius: 6px;
            padding: 8px;
            margin-bottom: 12px;
            margin-left: 15px;
            margin-right: 15px;
        }

        .success {
            color: #008000;
	    font-weight: bold;
        }

        .signature {
            font-style: italic;
            color: #555;
        }
    </style>
</head>
<body>

    <div class="email-container">
        <h1>Copia $bak_type creada con éxito</h1>
        <p>Se le informa que se ha creado correctamente la copia de seguridad $bak_type <strong>'${last_bak}'</strong> en el directorio <strong>'${bak_dir_location}'</strong>. Se le indica a continuación información relevante sobre la copia $bak_type realizada:</p>
        <div class="success-box">
            <p class="success">
		<code>
			<ul class="success">
    				<li>Fecha de creación: $date</li>
    				<li>Hora de finalización: $hour</li>
    				<li>Peso total: $weight</li>
			</ul>
		</code>
	    </p>
        </div>
	<p>También se le informa que se ha creado correctamente la copia de las bases de datos asociada a la copia $bak_type, con nombre <strong>'${last_db_bak}'</strong> en el directorio <strong>'${db_bak_dir_location}'</strong>. A continuación se proporcionan datos adicionales:</p>
	 <div class="success-box">
            <p class="success">
                <code>
                        <ul class="success">
                                <li>Fecha de creación: $db_date</li>
                                <li>Hora de finalización: $db_hour</li>
                                <li>Peso total: $db_weight</li>
                        </ul>
                </code>
            </p>
        </div>
        <p>Le agradecemos de antemano por su atención.</p>
        <p>Atentamente,</p>
        <p class="signature">Departamento de Administración de Syncbetter IT</p>
    </div>

</body>
</html>

EOF

exit 0

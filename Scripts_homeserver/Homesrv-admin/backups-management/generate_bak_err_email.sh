#!/bin/bash

err_file="/var/log/homeserver/backups/err.log"
management_dir="/root/Scripts/Homesrv-admin/backups-management"
last_comp_bak_err=$(/bin/cat $err_file | grep -E "c_" | awk '{print $3}' | sed "s/://g" | sed "s/'//g" | tail -n 1)
last_inc_bak_err=$(/bin/cat $err_file | grep -E "i_" | awk '{print $3}' | sed "s/://g" | sed "s/'//g" | tail -n 1)
last_log_id=$(/bin/cat $err_file | grep -E "(c_)|(i_)" | awk '{print $3}' | sed "s/://g" | sed "s/'//g" | tail -n 1)
last_err_log=$(/bin/cat $err_file | grep -E "(c_)|(i_)" | tail -n 1)
bak_type=""

if [[ -n $err_file ]]; then

	# Si err.log tiene contenido entonces hace lo siguiente

	if [[ "${last_log_id}" == "${last_comp_bak_err}" ]]; then
		# Si las última línea corresponde al error de copia completa
		bak_type="completa"
	elif [[ "${last_log_id}" == "$last_inc_bak_err" ]]; then
		# Si la última línea correspondiente al error de copia incremental
		bak_type="incremental"
	fi

fi

cat > $management_dir/templates/err_bak_email_template.html << EOF
From: Syncbetter IT <admin.syncbetter@gmail.com>
To: Marian <mariangeorgian24@gmail.com>
Subject: Error en copia de seguridad $bak_type
Content-Type: text/html

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error en copia de seguridad $bak_type</title>
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

        .error-box {
            background-color: #f6f8fa;
            border: 1px solid #d1d5da;
            border-radius: 6px;
            padding: 8px;
            margin-bottom: 12px;
            margin-left: 15px;
            margin-right: 15px;
        }

        .error {
            color: #d73a49;
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
        <h1>Error en copia $bak_type</h1>
        <p>Se ha producido recientemente un error relacionado con la copia de seguridad $bak_type en el servidor principal de Syncbetter IT. Le solicitamos amablemente que revise la situación lo antes posible.</p>
        <div class="error-box">
            <p class="error"><code>$last_err_log</code></p>
        </div>
        <p>Le agradecemos de antemano por su atención.</p>
        <p>Atentamente,</p>
        <p class="signature">Departamento de Administración de Syncbetter IT</p>
    </div>

</body>
</html>

EOF

exit 0

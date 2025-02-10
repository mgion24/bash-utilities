#!/bin/bash

# Script que se engarga de generar una plantilla de email html
# la cual se enviará al administrador. Se pueden agregar variables
# previamente recogidas, pero por ahora no se muestra ninguna.

dir="/root/Copias/Scripts_backups/Homesrv-admin/shutdown-management"
mail_template="${dir}/templates/shutdown_email_template.html"

cat > $mail_template << EOF
From: Syncbetter IT <admin.syncbetter@gmail.com>
To: Marian <mariangeorgian24@gmail.com>
Subject: Error en el apagado del servidor
Content-Type: text/html

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error en el apagado del servidor</title>
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

        .signature {
            font-style: italic;
            color: #555;
        }
    </style>
</head>
<body>

    <div class="email-container">
        <h1>Error en el apagado del servidor</h1>
        <p>Se ha producido recientemente un error relacionado con el apagado del servidor principal de Syncbetter IT. Le solicitamos amablemente que revise la situación lo antes posible.</p>
        <p>Le agradecemos de antemano por su atención.</p>
        <p>Atentamente,</p>
        <p class="signature">Departamento de Administración de Syncbetter IT</p>
    </div>

</body>
</html>

EOF

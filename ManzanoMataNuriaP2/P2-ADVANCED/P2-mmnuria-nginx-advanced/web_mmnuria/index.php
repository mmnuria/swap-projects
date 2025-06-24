<!DOCTYPE html>
<html>
<head>
    <title>Práctica 2 SWAP - Nuria Manzano Mata</title>
</head>
<body>
    <?php
    // Simular carga de 10 segundos
    sleep(10); 
    echo "Servidor: " . gethostname();
    ?>
    <h1>Práctica 2 SWAP - Nuria Manzano Mata</h1>
    <?php
        $server_ip = $_SERVER['SERVER_ADDR'];
        echo "<p>La dirección IP del servidor es: " . $server_ip . "</p>";
    ?>
</body>
</html>
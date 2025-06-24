<?php
session_start();
if (!isset($_SESSION['counter'])) {
    $_SESSION['counter'] = 1;
} else {
    $_SESSION['counter'] *= 2;
}
$loop = $_SESSION['counter'];
$sum = 0;
for ($i = 0; $i < $loop; $i++) {
    $sum += sqrt($i);
}
echo "Iteraciones: $loop - Resultado: $sum";
?>

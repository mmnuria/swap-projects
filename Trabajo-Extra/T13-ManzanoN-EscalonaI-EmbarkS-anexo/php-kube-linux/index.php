<?php
function fibonacci($n) {
    if ($n <= 1) return $n;
    return fibonacci($n - 1) + fibonacci($n - 2);
}

// Lee un parámetro para aumentar la carga
$load = isset($_GET['load']) ? (int)$_GET['load'] : 10;

$result = fibonacci($load);

echo "Fibonacci($load) = $result";
?>


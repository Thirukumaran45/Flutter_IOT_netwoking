<?php
include "config.php";

$user_id = $_POST['user_id'] ?? null;
if (!$user_id) {
    echo "not_logged_in";
    exit;
}

$tableName = "user_" . $user_id;

$name  = $_POST['name'] ?? '';
$age   = $_POST['age'] ?? '';
$email = $_POST['email'] ?? '';
$dob   = $_POST['dob'] ?? '';

if ($name && $age && $email && $dob) {
    $stmt = $con->prepare("INSERT INTO $tableName (name, age, email, dob) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("siss", $name, $age, $email, $dob);
    echo $stmt->execute() ? "true" : "false";
    $stmt->close();
} else {
    echo "missing_fields";
}

$con->close();
?>

<?php
include "config.php";

$user_id = $_POST['user_id'] ?? null;
if (!$user_id) {
    echo "not_logged_in";
    exit;
}

$tableName = "user_" . $user_id;

$id    = $_POST['id'] ?? '';
$name  = $_POST['name'] ?? '';
$age   = $_POST['age'] ?? '';
$email = $_POST['email'] ?? '';
$dob   = $_POST['dob'] ?? '';

if ($id && $name && $age && $email && $dob) {
    $stmt = $con->prepare("UPDATE $tableName SET name=?, age=?, email=?, dob=? WHERE id=?");
    $stmt->bind_param("sissi", $name, $age, $email, $dob, $id);
    echo $stmt->execute() ? "true" : "false";
    $stmt->close();
} else {
    echo "missing_fields";
}

$con->close();
?>

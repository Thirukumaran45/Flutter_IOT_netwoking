<?php
include "config.php";

// Either session or POST
session_start();
$user_id = $_SESSION['user_id'] ?? $_POST['user_id'] ?? null;
$record_id = $_POST['id'] ?? null;

if (!$user_id) {
    echo "not_logged_in";
    exit;
}

if (!$record_id) {
    echo "missing_id";
    exit;
}

// Target table for this user
$tableName = "user_" . $user_id;
$tableName = preg_replace('/[^a-zA-Z0-9_]/', '', $tableName);

$sql = "DELETE FROM $tableName WHERE id='$record_id'";
$res = $con->query($sql);

if ($res) {
    echo "true";
} else {
    echo "false";
}
?>

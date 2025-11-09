<?php
include "config.php";

$user_id = $_POST['user_id'] ?? null;
if (!$user_id) {
    echo json_encode([]);
    exit;
}

$tableName = "user_" . $user_id;

$sql = "SELECT * FROM $tableName ORDER BY id DESC";
$res = $con->query($sql);
$result = [];

if ($res->num_rows > 0) {
    while ($row = $res->fetch_assoc()) {
        $result[] = $row;
    }
}

echo json_encode($result);
$con->close();
?>

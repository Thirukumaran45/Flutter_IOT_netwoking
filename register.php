<?php
include "config.php";

// Get user input
$username = $_POST['username'];
$email = $_POST['email'];
$password = $_POST['password'];

// Hash the password securely
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// Use prepared statement to insert into authusers
$stmt = $con->prepare("INSERT INTO authusers (username, email, password) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $username, $email, $hashedPassword);

if ($stmt->execute()) {
    // Get the newly created user ID
    $user_id = $stmt->insert_id;

    // Create a dedicated table for this user
    $tableName = "user_" . $user_id;
    $createTableSQL = "CREATE TABLE $tableName (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
		age INT,
		email VARCHAR(100),
		dob VARCHAR(100)
    )";

    if ($con->query($createTableSQL) === TRUE) {
        echo json_encode([
            "success" => true,
            "message" => "Account created successfully! User table '$tableName' created."
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Account created, but failed to create user table: " . $con->error
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "Error creating account: " . $stmt->error
    ]);
}

$stmt->close();
$con->close();
?>

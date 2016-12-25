<?php
    require("urls.php");
    session_start();


    $email = $_POST["email"];
    $password = $_POST["password"];

    $request = sprintf('{"email":"%s","password":"%s"}',
            $email,$password);

    $ch = curl_init(URL::LOGIN_PROCESSING);

    curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $response = json_decode($response, true);


    if(isset($response['jwt'])){ // check if we got token
        setcookie("jwt", $response['jwt']);
        header('Location: '.URL::MAIN_PAGE);
        exit();
    }else{ // bad login
        $response = $response['status'];
        die(header("location: login.php?loginFailed=true&reason=password"));
    }

    curl_close($ch);
?>

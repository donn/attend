<?php
    session_start(); // start session saving token for all requests
?>
<!DOCTYPE html>
<html>
    <head>
        <title>attend Web</title>
        <link rel = "stylesheet" type="text/css" href="login.css">
    </head>

    <div id="parent">
        <body id="loginBody">

            <form method="post" action="web_login.php">

                Email:<br>
                <input type="text" name="email"><br><br>
                Password:<br>
                <input type="password" name="password"><br><br>
                <input type="submit" value = "Log in"/><br><br>

                <?php

                    $reasons = array("password" => "Email and password combination does not match any of our records.");
                    if (isset($_GET["loginFailed"]))
                        echo $reasons[$_GET["reason"]];
                ?>
            </form>
        </body>

    </div>
</html >

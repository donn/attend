<?php
  require("urls.php");

  setcookie("jwt", "", time() - 3600);

  header("Location: ".URL::LOGIN_PAGE);
  exit();
?>

<?php
  require("urls.php");
  if(!isset($_COOKIE["jwt"]) ){
      header("Location: ".URL::LOGIN_PAGE);
  }
?>

<!DOCTYPE html>
<html>

<head>
      <link rel = "stylesheet" type="text/css" href="course_info.css">
</head>

<body>
  <ul class="tab">
       <li><a href="YOUR_URL_HERE/website/main_page.php" class="tablinks">Back</a></li>
       <li><a href="YOUR_URL_HERE/website/logout.php" class="tablinks">Log out</a></li>
   </ul>

<form action="YOUR_URL_HERE/php/invite_bulk.php"
      method="post" enctype="multipart/form-data" id ="upload_form">
    <h3>Upload Student List</h3>

    Select .csv file to upload:
    <br />
    <input type="file" name="fileToUpload" id="fileToUpload">
    <input type="hidden" name="jwt" id="jwt">
    <input type="hidden" name="courseID" id="courseID"> <br /><br />
    <input type="submit" value="Upload" name="submit">
</form>

<div>

  <ul id="eventinstance_list">
      <?php
        ini_set('display_startup_errors', 1);
        ini_set('display_errors', 1);
        error_reporting(-1);

        $courseID = $_GET['courseID'];
        $token = $_COOKIE['jwt'];

        $request = sprintf('{"%s":"%s","%s":{"%s":"%s"}}',
          "jwt",$token,"request","CourseID",$courseID);

        $ch = curl_init("YOUR_URL_HERE/php/get.php?type=eventinstance");

        curl_setopt($ch,CURLOPT_POSTFIELDS,$request);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $response = curl_exec($ch);
        $response = json_decode($response,true);

        $response = $response['response'];

        foreach($response as $class){
        //    echo "<li>".$class["Title"]." "
          //  .$class["StartTime"] ."</li>"."";
          $qrCodeLink = "https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl="
            ."miniAttendCode:".$class["QRString"];
          echo sprintf('<li id="li_event"> %s  %s <a href="%s" download>%s</a>',
            $class["Title"],$class["StartTime"],$qrCodeLink,
            "Download QR Code");

          echo sprintf(' <a href="%s">%s</a> </li>',$qrCodeLink,
          "View QR Code");
        }
      ?>
  </ul>
</div>

<script>
  var jwt = document.cookie;
  var courseID = "<?= $_GET['courseID']; ?>";
  var title = "<?= $_GET['Title']; ?>";

  var jwtFormat = new RegExp('jwt=.*;');
  var token = jwt.match(jwtFormat)[0];
  token = token.substring(4,token.length-1);

//   alert("title" + title);
//   alert(courseID);

  document.title = title;
  document.getElementById('jwt').value = token;
  document.getElementById('courseID').value = courseID;
</script>



</body>
</html>

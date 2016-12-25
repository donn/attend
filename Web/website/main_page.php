<?php
    require("urls.php");
    session_start();

    if(!isset($_COOKIE['jwt'])){
        header('Location: login.php');
    }
?>
<!DOCTYPE html>
<html>
<head>
    <script src="http://ajax.aspnetcdn.com/ajax/jQuery/jquery-1.12.4.min.js"></script>
        <script type="text/javascript">
            function moveToTab(evt, cityName) {
                var i, tabcontent, tablinks;
                tabcontent = document.getElementsByClassName("tabcontent");
                for (i = 0; i < tabcontent.length; i++) {
                    tabcontent[i].style.display = "none";
                }
                tablinks = document.getElementsByClassName("tablinks");
                for (i = 0; i < tablinks.length; i++) {
                    tablinks[i].className = tablinks[i].className.replace(" active", "");
                }
                document.getElementById(cityName).style.display = "block";
                evt.currentTarget.className += " active";
            }
        </script>
        <script>
            function getCookie(name) {
                var value = "; " + document.cookie;
                var parts = value.split("; " + name + "=");
                if (parts.length == 2) return parts.pop().split(";").shift();
            }
            function createClass() {
                var token = getCookie("jwt");

                // alert(token);
                var request0 = {
                    Title: document.getElementById("courseName").value,
                    Section: document.getElementById("courseSection").value,
                    Code: document.getElementById("courseCode").value,
                    MissableEvents: document.getElementById("maxAbsences").value
                };

                var jsonToSend = {
                    jwt: token,
                    request: request0                   
                };

                var json_str = JSON.stringify(jsonToSend);

                if(courseName.length == 0) {
                  alert("Must have Course Name specified");
                } else {
                    var request = new XMLHttpRequest();

                    request.onreadystatechange = function() {
                        if (request.readyState == XMLHttpRequest.DONE && request.status == 200) {
                            //   alert("Successful");
                            alert("Class has been created");
                        } else {
                            // alert(json_str);
                            // alert(request.responseText);
                        }
                    };

                    request.open("POST", "YOUR_URL_HERE/php/create.php?type=course", true);

                    request.setRequestHeader("Content-type", "application/json");

                    request.send(json_str);
                }
            }
    </script>
</head>
    <head>
        <title>attend Web</title>
        <link rel = "stylesheet" type="text/css" href="main_page.css">
    </head>

    <body>


       <ul class="tab">
            <li><a href="#" class="tablinks" onclick="moveToTab(event, 'ClassesList')">Classes</a></li>
            <li><a href="#" class="tablinks" onclick="moveToTab(event, 'CreateClass')">Class Create</a></li>
            <li><a href="YOUR_URL_HERE/website/logout.php" class="tablinks">Log out</a></li>
        </ul>


        <div id="ClassesList" class="tabcontent">
            <?php
              require_once ("./urls.php");
              $request = sprintf('{"jwt":"%s"}',$_COOKIE['jwt']);

              $ch = curl_init("YOUR_URL_HERE/php/get.php?type=course&managed");

              curl_setopt($ch,CURLOPT_POSTFIELDS,$request);
              curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

              $response = curl_exec($ch);
              $response = json_decode($response,true);

              $response = $response['response'];

              echo "<ul>";
              foreach ($response as $item){
                //echo "<li>".$item["Title"]." < </li>";(ID: ".$item["ID"].")

                 echo sprintf('<li> <a href="%s">%s</a> </li>', URL::UPLOAD_CSV.
                   "?courseID=".$item["ID"]."&Title=".$item["Title"], $item["Title"]);
              }

              echo "</ul>";
            ?>
        </div>

        <div id="CreateClass" class="tabcontent">

          <div id="classCreateForm">

              Course name:<br>
              <input type="text" id="courseName"><br><br>
              Course section:<br>
              <input type="text" id="courseSection"><br><br>
              Course Code:<br>
              <input type="text" id="courseCode"><br><br>
              Maximum Absences</br>
              <input type="number" id="maxAbsences"/></br>

              <input type="button" value = "Create" onclick="createClass()"/><br>

          </div>

        </div>
    </body>
</html >

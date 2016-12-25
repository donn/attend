<?php
	  //Libraries
    require_once './lib/meekrodb.php';
	  require_once './lib/jwt/JWT.php';
	  use \Firebase\JWT\JWT;

	   //Includes
    require_once './utils.php';
    require_once './db_connect.php';



    $token = $_POST['jwt'];
//	$decoded = '';

	try {
		$decoded = JWT::decode($token, $JWT_KEY, ['HS256']);
	}
	catch(Exception $e) {
		fail(999, 'unknown token '.$token."empty token");
	}

   $fileString = file_get_contents($_FILES["fileToUpload"]["tmp_name"]);

  // $token = $_POST['jwt'];
   $courseID = $_POST['courseID'];

   //echo $fileString;

   $emails_list = str_getcsv($fileString,',');
   //echo json_encode($emails_list);

   $added_count = 0;
   $absentia_count = 0;
   $error_count = 0;


   foreach ($emails_list as $email)
   {
      $result = DB::queryFirstRow("SELECT ID, count(*) as Count
          FROM User
          WHERE RegistrationEmail = %s", $email);

      if(intval($result['Count']) > 0)
      {

        $exist = DB::queryFirstRow(
        'SELECT count(*) as Count
        from Involvement
        where CourseID = %i
        and UserID = %i
        ', $courseID, $result['ID']);

        if (intval($exist['Count']) === 0)
        {
            DB::query("INSERT INTO Involvement values
            (%i, %i, 'S', 0, 0)",$result['ID'],$courseID);

            $added_count++;
        }
        else
        {
          $error_count++;
        }
      }else{
          $isPresent = DB::queryFirstRow(
          'SELECT count(*) as Count
          from StudentInAbsentia
          where Email = %s and CourseID = %i
          ',$email
          ,$courseID);

          if(intVal($isPresent['Count']) === 0){
            DB::query("INSERT INTO StudentInAbsentia values (%s,%i)",
              $email, $courseID);
              $absentia_count++;
          }else{
            $error_count++;
          }
      }


   }

   die("Successfully added {$added_count} student(s). {$error_count} student(s) were already registered. {$absentia_count} student(s) added in absentia.");

?>

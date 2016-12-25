<?php
  /*
		THIS FILE IS DEPRECATED.

		It's functionally identical to get.php?type=event
	*/

  //Libraries
  require_once './lib/meekrodb.php';
  require_once './lib/jwt/JWT.php';
  use \Firebase\JWT\JWT;

  //Includes  
  require_once './db_connect.php';
  require_once './utils.php';
  
  $data = json_decode(file_get_contents('php://input'), true);

  $necessary_fields = ['jwt' , 'request'];
  if($data === null || !check_json_fields($data, $necessary_fields))
    fail(400, 'malformed JSON request body');

  $potential_jwt = $data['jwt'];

  try {
    $UserID = JWT::decode($potential_jwt, $JWT_KEY, ['HS256'])->UID;
  }
  catch(Exception $e) {
    fail(999, 'unknown token');
  }
  
  $request_info = $data['request'];

  $necessary_fields = ['CourseID'];

  if ($request_info === null || !check_json_fields($request_info, $necessary_fields))
    fail(400, 'malformed JSON request body');

  //Check for Privilege  
  $query = DB::queryFirstRow(
		'SELECT count(*) as Count
		from Involvement
		where UserID = %i
		and CourseID = %i
		and Privilege >= 1
		', $UserID
		, $request_info['CourseID']);

if (intval($query['Count']) === 0)
	{
			fail(401, 'insufficient privileges');
  }

  $query_result = DB::query('SELECT * FROM Event WHERE CourseID = %d',
    $request_info['CourseID']);
    
  foreach ($query_result as $resp_item)
    {
      $sample_response = array('ID'=>$resp_item['ID'], 'CourseID'=>$resp_item['CourseID'],
        'Title'=>$resp_item['Title'],'IsSpecial'=>$resp_item['IsSpecial'],
        'TypicalStartTime'=>$resp_item['TypicalStartTime'],
        'TypicalEndTime'=>$resp_item['TypicalEndTime']);

      $days_query = DB::query('SELECT DayCharacter FROM Event_TypicalDays where EventID = %d',$resp_item['ID']);
      $days_string = '';

      foreach($days_query as $day){
        $days_string = $days_string.$day['DayCharacter']." ";
      }

      $sample_response['Event_TypicalDays'] = $days_string;
      $response['request'][] = $sample_response;
    }

  $response = [
		'status' => [
			'code' => 200
			, 'msg' => 'list sent']
		, 'response' => $response
	];


    echo json_encode($response);
?>

<?php
  /*
		THIS FILE IS DEPRECATED.

		It's functionally identical to get.php?type=upcomingevent
	*/
  
  //Libraries
  require_once './lib/meekrodb.php';
  require_once './lib/jwt/JWT.php';
  use \Firebase\JWT\JWT;

  //Includes  
  require_once './db_connect.php';
  require_once './utils.php';

  $data = json_decode(file_get_contents('php://input'), true);

  $necessary_fields = ['jwt'];
  if($data === null || !check_json_fields($data, $necessary_fields))
    fail(400, 'Malformed JSON request body');

  $potential_jwt = $data['jwt'];

  $UserID = '';
  try {
    $decoded = JWT::decode($potential_jwt, $JWT_KEY, ['HS256']);
  }
  catch(Exception $e) {
    fail(401, 'Unknown token');
  }

  $time = strval(date('H:i:s'));
  $unixtime = date_timestamp_get(date_create());
  
  $DoW = date('w');
  switch($DoW)
  {
    case 0:
    $DoW = 'U';
    break;
    case 1:
    $DoW = 'M';
    break;
    case 2:
    $DoW = 'T';
    break;
    case 3:
    $DoW = 'W';
    break;
    case 4:
    $DoW = 'R';
    break;
    case 5:
    $DoW = 'F';
    break;
    case 6:
    $DoW = 'S';
    break;
    default:
    fail(999, 'PHP error');
  }

  //Queries
  $student_events = DB::queryFirstRow(
    'SELECT *, TypicalStartTime as StartTime
    from Event
    where IsSpecial = "N"
    and CourseID in
    (
      Select ID
      from Course
      where CourseID in
      (
        Select CourseID
        from Involvement
        where UserID = %i
        and DoICode = "S"
      )
    )
    and ID in
    (
      Select EventID
      from Event_TypicalDays
      where DayCharacter = %s
    )
    and TypicalStartTime > %s
    order by TypicalStartTime asc       
    ', $decoded->UID, $DoW, $time);

    $student_eventinstances_query = sprintf('SELECT *, FROM_UNIXTIME(UnixStartTime, \'%%h:%%i:%%s\') as StartTime
      from EventInstanceExpanded
      where UnixStartTime >= UNIX_TIMESTAMP(CURDATE())
      and EventID in
      (
          Select ID
          from Event
          where CourseID in
          (
              Select ID
              from Course
              where ID in
              (
                  Select CourseID
                  from Involvement
                  where UserID = %d
                  and DoICode = "S"
              )    
          )
      )
      and (UnixStartTime + 600) > %d
      order by UnixStartTime asc
      ', $decoded->UID, $unixtime); //MeekroDB, the epitome of shit escaping

    $student_eventinstances = DB::queryFirstRow($student_eventinstances_query);
     
    //Compare and pick
    if ($student_events !== null && $student_eventinstances === null)
    {
      $finale = $student_events;
    }
    elseif ($student_events === null && $student_eventinstances !== null)
    {
      $finale = $student_eventinstances;
    }
    elseif ($student_events === null && $student_eventinstances === null)
    {
      $response = [
        'status' => [
        'code' => 200
        , 'msg' => 'list sent']
        , 'response' => null
        ];
      echo json_encode($response);
      die();
    }
    else
    {
      if ($student_eventinstances['EventID'] === $student_events['ID'])
      {
        $finale = $student_eventinstances;
      }
      else
      {
        $eventTime = $student_events['TypicalStartTime']; //Get typical start time
        $eventTimeExploded = explode(':', $eventTime); //Explode it into hours, minutes and seconds
        $eventTimestamp = new DateTime(); //Create today's timestamp
        $eventTimestamp->setTime(intval($eventTimeExploded[0]), intval($eventTimeExploded[1]), intval($eventTimeExploded[2])); //Set the time to the event's
        $eventTimestamp = $eventTimestamp->getTimestamp() + 600; //Get UNIX timestamp, add 10 minute 'penalty' because not instantiated      

        $eventInstanceTimestamp = $student_eventinstances['UnixStartTime']; //Already unix timestamp in the view

        $finale = ($eventTimestamp < $eventInstanceTimestamp)?$student_events:$student_eventinstances;
      }
    }

    //Encode and leave
    $response->Title = $finale['Title'];
    $response->CourseID = $finale['CourseID'];
    $response->StartTime = $finale['StartTime'];
    $response->IsSpecial = ($finale['IsSpecial'] == 'Y')?true:false;
    $response = [
        'status' => [
        'code' => 200
        , 'msg' => 'response sent']
        , 'response' => $response
        ];
      echo json_encode($response);
      die();
?>

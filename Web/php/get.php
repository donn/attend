<?php
	 //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';

    if (!isset($_GET['type']))
		fail(400, 'malformed GET call');

	$type = $_GET['type'];

	if($type != 'course' && $type != 'event' && $type != 'eventinstance' && $type != 'upcomingevent' && $type != 'enrolled' && $type != 'enrolledcount')
		fail(400, 'malformed GET call');

    $data = json_decode(file_get_contents('php://input'),true);

    //Check request integrity
    $necessary_fields = ($type == 'course' || $type == 'upcomingevent')? ['jwt']: ['jwt', 'request'];
	if($data === null || !check_json_fields($data, $necessary_fields))
		fail(400, 'malformed JSON request body');

    $potential_jwt = $data['jwt'];
	$decoded = '';

	try {
		$decoded = JWT::decode($potential_jwt, $JWT_KEY, ['HS256']);
	}
	catch(Exception $e) {
		fail(999, 'unknown token');
	}

	$skip = false;

    if ($type == 'course' || $type != 'upcomingevent')
    {
        $skip = true;
    }
	elseif ($type == 'event' || $type == 'enrolled' || $type == 'eventinstance' || $type == 'enrolledcount')
	{
		$necessary_fields = ['CourseID'];
	}
    
    $request = $data['request'];

    if(!skip && !check_json_fields($request, $necessary_fields))
	{
		fail(400, 'malformed JSON request body');
	}

	//Actual Getting
	if ($type == 'course')
	{
		if (isset($_GET['managed']))
		{
			$courses = DB::query(
			'SELECT *
			from Course
			where ID in
			(
				Select CourseID
				from Involvement
				where UserID = %i
				and Privilege >= 2
			)
			', $decoded->UID);

			$list = [
			'status' => [
				'code' => 200
				, 'msg' => 'list sent']
			, 'response' => $courses
			];

			echo json_encode($list);
			die();
		}

		$course_id_s = DB::query(
			'SELECT *
			from Involvement
			WHERE UserID = %i',
			$decoded->UID);

		$list = array();

		// main course data
		foreach ($course_id_s as &$inv)
		{
			$cid = $inv['CourseID'];

			//Course (and its MissableEvents)
			$course = DB::queryFirstRow('SELECT * FROM Course WHERE ID = %i ', $cid);

			//Total Events
			DB::query('SELECT * from EventInstanceExpanded where CourseID = %i and IsSpecial = "N"', $cid);
			$total_events = strval(DB::count());

			//Attended Events
			DB::query(
				'SELECT *
				from Attendance
				where EventInstanceID in
				(
					Select ID
					from EventInstanceExpanded
					where CourseID = %i					
					and IsSpecial = "N"
				)
				and UserID = %i', $cid, intval($decoded->UID)
			);
			$attended_events = strval(DB::count());
			
			//People of Interest		
			$peopleOfInterest = DB::query(
				'SELECT *
				from Involvement
				where CourseID = %i
				and DoICode != "S"
				order by Privilege desc
			', $cid);		

			$poi_array = array();

			foreach ($peopleOfInterest as $personOfInterest)
			{
				$cp = null;

				$cp->DoICode = $personOfInterest['DoICode'];

				$getPerson = DB::queryFirstRow(
					'SELECT *
					from User
					where ID = %i', $personOfInterest['UserID']
				);

				$cp->FirstName = $getPerson['FirstName'];
				$cp->LastName = $getPerson['LastName'];
				$cp->Email = $getPerson['RegistrationEmail'];

				$poi_array[] = $cp;
			}

			
			$course = array_merge($course, [ 				
					'DoI' => $inv['DoICode']
					, 'Privilege' => $inv['Privilege']
					, 'TotalEvents' => $total_events
					, 'AttendedEvents' => $attended_events
					, 'ExcusedAbsences' => $inv['ExcusedAbsences']
					, 'PeopleOfInterest' => $poi_array
					]);

			$list[] = $course;
		}

		$response = [
			'status' => [
				'code' => 200
				, 'msg' => 'list sent']
			, 'response' => $list
		];

		echo json_encode($response);
		die();
	}
	elseif ($type == 'event')
	{
		//Check for Course
		$exist = DB::queryFirstRow(
			'SELECT count(*) as Count
			from Course
			where ID = %i
			', $request['CourseID']
		);

		if (intval($exist['Count']) === 0)
		{
				fail(404, 'course not found');
		}

		//Check for Privilege  
		$query = DB::queryFirstRow(
				'SELECT Privilege, count(*) as Count
				from Involvement
				where UserID = %i
				and CourseID = %i
				and Privilege >= 1
				', $decoded->UID
				, $request['CourseID']);

		if (intval($query['Count']) === 0)
		{
				fail(401, 'insufficient privileges');
		}

		$query_result = DB::query(
			'SELECT *
			FROM Event
			WHERE CourseID = %i
			and (IsSpecial = "Y"
			or IsSpecial = %s)
			', $request['CourseID']
			, ($query['Privilege'] >= 2)? "N": "Y");
		
		foreach ($query_result as $resp_item)
		{
			$current = array('ID'=>$resp_item['ID'],
				'CourseID'=>$resp_item['CourseID'],
				'Title'=>$resp_item['Title'],
				'Special'=> ($resp_item['IsSpecial'] == 'Y'),
				'TypicalStartTime'=>$resp_item['TypicalStartTime']);

			$days_query = DB::query(
				'SELECT DayCharacter
				from Event_TypicalDays
				where EventID = %d'
				,$resp_item['ID']);
			
			/*
			// @Deprecated
			$days_string = '';

			foreach($days_query as $day){
				$days_string = $days_string.$day['DayCharacter']." ";
			}

			$sample_response['Event_TypicalDays'] = $days_string;
			$response['request'][] = $sample_response;*/

			$response[] = $current;
		}

		$response = [
				'status' => [
					'code' => 200
					, 'msg' => 'list sent']
				, 'response' => $response
			];

		echo json_encode($response);
		die();
	}
	elseif ($type=='eventinstance')
	{
		//Check for Privilege  
		$query = DB::queryFirstRow(
				'SELECT count(*) as Count
				from Involvement
				where UserID = %i
				and CourseID = %i
				and Privilege >= 1
				', $decoded->UID
				, $request['CourseID']);

		if (intval($query['Count']) === 0)
		{
			fail(401, 'insufficient privileges');
		}

		$result = DB::query(
			'SELECT * from EventInstanceExpanded
			where CourseID = %i 
			and UnixStartTime + 86400 > UNIX_TIMESTAMP() 
			order by UnixStartTime asc
			', $request['CourseID']
		);

		$response = [
			'status' => [
				'code' => 200,
				'msg' => 'event instances listed'
			],
			'response' => $result
		];

		echo json_encode($response);
		die;
	}
	elseif ($type=='upcomingevent')
	{
		/*
		// @Deprecated

		$time = strval(date('H:i:s'));
		
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
			fail(500, 'PHP error');
		}
		

		//Queries
		$student_events = DB::queryFirstRow(
			'SELECT *, TypicalStartTime as StartTime, count(*) as Count
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
			', $decoded->UID, $DoW, $time);*/

		$student_eventinstances_query = sprintf('SELECT *, FROM_UNIXTIME(UnixStartTime, \'%%H:%%i:%%s\') as StartTime, count(*) as Count
			from EventInstanceExpanded
			where (UnixStartTime + 600) >= UNIX_TIMESTAMP()
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
					)    
				)
			)
			order by UnixStartTime asc
			', $decoded->UID); //MeekroDB, the epitome of shit escaping

		$student_eventinstances = DB::queryFirstRow($student_eventinstances_query);
		
		/*
		// @Deprecated
		//Compare and pick
		if (intval($student_events['Count']) !== 0 && intval($student_eventinstances['Count']) === 0)
		{
			$finale = $student_events;
		}
		elseif (intval($student_events['Count']) === 0 && intval($student_eventinstances['Count']) !== 0)
		{
			$finale = $student_eventinstances;
		}
		elseif (intval($student_events['Count']) === 0 && intval($student_eventinstances['Count']) === 0)
		{
			$response = [
				'status' => [
				'code' => 200
				, 'msg' => 'response sent']
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
				echo $eventTimestamp;

				$eventInstanceTimestamp = $student_eventinstances['UnixStartTime']; //Already unix timestamp in the view

				$finale = ($eventTimestamp < $eventInstanceTimestamp)?$student_events:$student_eventinstances;
			}
		}*/

		$finale = DB::queryFirstRow($student_eventinstances_query);

		if (intval($finale["Count"]) === 0)
		{
			$response = [
			'status' => [
			'code' => 200
			, 'msg' => 'response sent']
			, 'response' => null
			];
			echo json_encode($response);
		die();
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
	}
	elseif ($type == 'enrolled')
	{
		$cid = $request['CourseID'];

		$query = DB::queryFirstRow(
				'SELECT count(*) as Count
				from Involvement
				where UserID = %i
				and CourseID = %i
				and Privilege >= 1
				', $decoded->UID
				, $cid);

		if (intval($query['Count']) === 0)
		{
				fail(401, 'insufficient privileges');
		}

		$students = DB::query(
				'SELECT *
				from Involvement
				where CourseID = %i
				and DoICode = "S"
			', $cid);
		
		$response = ["students" => $students];

		$response = [
			'status' => [
			'code' => 200
			, 'msg' => 'response sent']
			, 'response' => $response
			];

		echo json_encode($response);
		die();
		
	}
	elseif ($type == 'enrolledcount')
	{
		$cid = $request['CourseID'];

		$query = DB::queryFirstRow(
				'SELECT count(*) as Count
				from Involvement
				where UserID = %i
				and CourseID = %i
				and Privilege >= 1
				', $decoded->UID
				, $cid);

		if (intval($query['Count']) === 0)
		{
				fail(401, 'insufficient privileges');
		}

		$students = DB::query(
				'SELECT count(*) as Count
				from Involvement
				where CourseID = %i
				and DoICode = "S"
			', $cid);
		
		$response = ["students" => $intval($students['Count'])];

		$response = [
			'status' => [
			'code' => 200
			, 'msg' => 'response sent']
			, 'response' => $response
			];

		echo json_encode($response);
		die();
		
	}
?>
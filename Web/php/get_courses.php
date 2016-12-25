<?php
	/*
		THIS FILE IS DEPRECATED.

		It's functionally identical to get.php?type=course
	*/

	//Libraries
	require_once './lib/meekrodb.php';
	require_once './lib/jwt/JWT.php';
	use \Firebase\JWT\JWT;

	//Includes	
	require_once './db_connect.php';
	require_once './utils.php';

	$data = json_decode(file_get_contents('php://input'), true);

	$necessary_fields = ['jwt' /*, 'request', */];

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

	$course_id_s = DB::query('SELECT * from Involvement WHERE UserID=%i', $decoded->UID);

	$list = array();

	// main course data
	foreach ($course_id_s as &$inv)
	{
		$cid = $inv['CourseID'];

		//Course (and its MissableEvents)
		$course = DB::queryFirstRow('SELECT * FROM Course WHERE ID = %i ', $cid);

		//Total Events
		DB::query('SELECT * from EventInstance where EventID in (Select ID from Event where CourseID = %i and IsSpecial = "N")', $cid);
		$total_events = strval(DB::count());

		//Attended Events
		DB::query(
			'SELECT *
			from Attendance
			where EventInstanceID in
			(
				Select ID
				from EventInstance
				where EventID in
				(
					Select ID
					from Event
					where CourseID = %i					
					and IsSpecial = "N"
				)
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

	$list = [
		'status' => [
			'code' => 200
			, 'msg' => 'list sent']
		, 'response' => $list
	];

	echo json_encode($list);

	// echo $list;
?>
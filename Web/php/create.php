<?php
	//Libraries
	require_once './lib/meekrodb.php';
	require_once './lib/jwt/JWT.php';
	use \Firebase\JWT\JWT;

	//Includes	
	require_once './db_connect.php';
	require_once './utils.php';
	// fail(800, 'blah');
	
	if (!isset($_GET['type']))
		fail(400, 'malformed GET call');

	$type = $_GET['type'];


	if($type != 'course' && $type != 'event' && $type != 'eventinstance')
		fail(400, 'malformed GET call');		

	$data = json_decode(file_get_contents('php://input'), true);
	
	$necessary_fields = ['jwt', 'request'];
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

	//This should be obvious, but nullables aren't necessary.
	if ($type == 'course')
	{
	$necessary_fields = [
						'Title'
					 ];
	}
	elseif ($type == 'event')
	{	
	$necessary_fields = [ 'CourseID'
					  , 'Title'
					  , 'Special'
				  ];
	}
	elseif ($type == 'eventinstance') {
		$necessary_fields = [ 'EventID'
					  , 'StartTime'
					  , 'QRCodeActive'
				  ];
	}	

	// Matching terms across components of a program is a virtue; I'm not awake enough to translate manually between 'special' and 'IsSpecial'
	// \_(ツ)_/ 
	$request_info = $data['request'];

	if(!check_json_fields($request_info, $necessary_fields))
		{
			fail(400, 'malformed JSON request body');
		}

	if($type == 'course'){ // should create course

		$auth = DB::queryFirstRow(
			'SELECT count(*) as Count
			from User
			where ID = %i
			and IsVerifiedProfessor = "Y"',
			$decoded->UID
		);

		if (intval($auth['Count']) === 0)
		{
			fail(401, 'only verified professors may create courses');
		}

		$query = sprintf(
			'INSERT into Course values
				(null, "%s", %s, %s, %s)			
			', $request_info['Title'], sql_str_null_unwrap($request_info['Code']), sql_str_null_unwrap($request_info['Section']), sql_null_unwrap($request_info['MissableEvents'])
		);

		if (DB::query($query) !== array()){ // return data
			DB::insert('Involvement', [
					'UserID' => intval($decoded->UID),
					'CourseID' => DB::InsertId(),
					'DoICode' => 'P',
					'Privilege' => 2,
					'ExcusedAbsences' => 0
				]);

			$status = array("code"=>200,"msg"=>"created");
			$success = array('status'=>$status);
			echo json_encode($success);
		} else {
			fail(500, 'failed to create class');
		}
	}
	else if ($type == 'event')
	{ 
		$query = DB::queryFirstRow(
		'SELECT count(*) as Count
		from Involvement
		where UserID = %i
		and CourseID = %i
		and Privilege >= %i
		', intval($decoded->UID)
		, $request_info['CourseID']
		, ($request_info['Special'])? 1: 2);


		if (intval($query['Count']) === 0)
		{
			fail(401, 'insufficient privileges');
		}

		$query = sprintf('INSERT INTO Event
			(CourseID, Title, IsSpecial, TypicalStartTime)
				VALUES
			(%d, "%s", "%s", %s)',
			$request_info['CourseID'],
			$request_info['Title'],
			$request_info['Special']?'Y':'N',
			sql_str_null_unwrap($request_info['TypicalStartTime'])
			);	
		

		if(DB::query($query) !== array())
		{
			$days = explode(' ', $request_info['days']);
			$event_id = DB::insertId();

			foreach ($days as $day)
			{
				if ($day !== '')
				{
					DB::query(
					'INSERT into Event_TypicalDays VALUES
						(%i, %s) 
					', $event_id, $day 
					);
				}
			}
			$status = array("code"=>200,"msg"=>"created");
			$success = array('status'=>$status);
			echo json_encode($success);

		} else {
			fail(400,'failed to create event');
		}
	}
	else //Create event instance
	{

		$special = (DB::queryFirstRow(
			'SELECT IsSpecial
			from Event
			where ID = %i', $request_info['EventID']
		)['IsSpecial'] == 'Y');
		
		$query = DB::queryFirstRow(
		'SELECT count(*) as Count
		from Involvement
		where UserID = %i
		and CourseID in
		(
			Select CourseID
			from Event
			where ID = %i
		)
		and Privilege >= %i
		', intval($decoded->UID)
		, $request_info['EventID']
		, $special? 1: 2);

		if (intval($query['Count']) === 0)
		{
			fail(401, 'insufficient privileges');
		}

		$count = 1;
		
		while ($count >= 1)
		{
			$potentialqr = rand(100000, 999999);

			//First, clear old records.
			DB::query(
				'UPDATE EventInstance
    			set QRString = null
    			where UNIX_TIMESTAMP(StartTime) + 86400 <= UNIX_TIMESTAMP(CURDATE());'
			);

			$count = DB::queryFirstRow(
				'SELECT count(*) as Count
				from EventInstance
				where QRString = %s
				', strval($potentialqr)
			)['Count'];
		}

		$query = DB::queryFirstRow(
		'INSERT into EventInstance values
			(null, %s, FROM_UNIXTIME(%i), %s, %s, "N")
		',
		$request_info['EventID'], $request_info['StartTime'], strval($potentialqr), $request_info['QRCodeActive']?'Y':'N');		
		
		if($query !== array())
		{
			$status = array("code"=>200,"msg"=>"created");
			$success = array('status'=>$status);
			echo json_encode($success);

		} else {
			fail(400,'failed to instantiate event');
		}
	}
?>

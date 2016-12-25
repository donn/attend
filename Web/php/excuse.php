<?php

    //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';

    ini_set('display_errors', 1);
	ini_set('display_startup_errors', 1);

    $data = json_decode(file_get_contents('php://input'),true);

    //Check request integrity
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

    $necessary_fields = ['CourseID', 'Email'];
    
    $request = $data['request'];

    if(!check_json_fields($request, $necessary_fields))
	{
		fail(400, 'malformed JSON request body');
	}

    $issuer_id = $decoded->UID;
        $boss = DB::queryFirstRow(
            'SELECT Privilege
            FROM Involvement
            WHERE UserID = %i
            and CourseID = %i
            ', $issuer_id
            , $request['CourseID']
        );

        if(intval($boss['Privilege']) < 2) {
            fail(401, 'unauthorized excuse request');
        }

        $getUID = DB::queryFirstRow(
            'SELECT ID, count(*) as Count
            from User
            where RegistrationEmail = %s
            ', $request['Email']
        );

        if (intval($getUID['Count']) === 0)
        {
            fail(404, 'user does not exist');
        }

        $exist = DB::queryFirstRow(
            'SELECT ExcusedAbsences, count(*) as Count
            from Involvement
            where UserID = %i
            and CourseID =  %i
            ', $getUID['ID'], $request['CourseID']
        );

        if (intval($exist['Count']) === 0)
        {
            fail(403, 'user not in course');
        }

        $currentAbsences = intval($exist['ExcusedAbsences']);
        
        $currentAbsences = $currentAbsences + 1;

        $update = DB::query(
            'UPDATE Involvement
            set ExcusedAbsences = %i
            where UserID = %i
            and CourseID = %i
            ', $currentAbsences
            , $getUID['ID']
            , $request['CourseID']
        );

        $response = [
            'status' => [
                'code' => 200,
                'msg' => 'excused'
            ]
        ];

        echo json_encode($response);

?>
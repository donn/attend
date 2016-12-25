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

    if (!isset($_GET['type']))
		fail(400, 'malformed GET call');

	$type = $_GET['type'];

	if($type != 'eventinstance' && $type != 'involvement')
		fail(400, 'malformed GET call');

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

    if ($type == 'eventinstance')
    {
        $necessary_fields = ['ID', 'RegenerateQR', 'Late', 'QRCodeActive'];
    }
    elseif ($type == 'involvement')
    {
        $necessary_fields = ['Email', 'CourseID', 'DoICode', 'Privilege'];        
    }
    else {
        fail('never happening');
    }
    
    $request = $data['request'];

    if(!check_json_fields($request, $necessary_fields))
	{
		fail(400, 'malformed JSON request body');
	}

    if ($type == 'eventinstance')
    {
        // Check existence, currency
        $checkExistence = DB::queryFirstRow(
            'SELECT *, count(*) as Count
            from EventInstanceExpanded
            where ID = %i
            and UNIX_TIMESTAMP(StartTime) + 86400 > UNIX_TIMESTAMP(CURDATE())   
            ', $request['ID']
        );
        
        if (intval($checkExistence['Count']) === 0)
        {
            fail(404, 'instance out of date or does not exist');
        }

       $qr = $checkExistence['QRString'];

        // Check authorization
        $checkAuthorization = DB::queryFirstRow(
            'SELECT count(*) as Count
            from Involvement
            where CourseID = %i
            and UserID = %i
            and Privilege >= %i
            ', $checkExistence['CourseID']
            , $decoded->UID
            , ($checkExistence['IsSpecial'] == "Y")? 1: 2
        );

        if (intval($checkAuthorization['Count']) === 0)
        {
            fail(401, 'unauthorized');
        }

        //Regenerate QR if asked to
        if ($request['RegenerateQR'])
        {
            $count = 1;
		    $potentialqr = 0;

            while ($count >= 1)
            {
                $potentialqr = rand(100000, 999999);

                //First, clear old records.
                DB::query(
                    'UPDATE EventInstance
                    set QRString = null
                    where UNIX_TIMESTAMP(StartTime) + 86400 <= UNIX_TIMESTAMP(CURDATE());');

                $count = DB::queryFirstRow(
                    'SELECT count(*) as Count
                    from EventInstance
                    where QRString = %s
                    ', strval($potentialqr)
                )['Count'];
            }

            $qr = strval($potentialqr);
        }

        // Update
        $result = DB::queryFirstRow(
            'UPDATE EventInstance
            set IsQRCodeActive = %s,
            IsLate = %s,
            QRString = %s
            where ID = %i
            ', bool_char($request['QRCodeActive'])
            , bool_char($request['Late'])
            , $qr,
            $request['ID']
        );

        if ($result !== array())
        {
            $response = ['QRString' => $qr];
            $response = [
                        'status' => [
                            'code' => 200
                            , 'msg' => 'done']
                        , 'response' => $response
                    ];
            
            echo json_encode($response);
            die();
        }
        else
            fail(500, 'server error');       
    }
    elseif ($type === 'involvement') {
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
            fail(401, 'unauthorized addition request');
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
            'SELECT count(*) as Count
            from Involvement
            where UserID = %i
            and CourseID =  %i
            ', $getUID['ID'], $request['CourseID']
        );

        if (intval($exist['Count']) !== 0)
        {
            $affected = DB::query(
            'UPDATE Involvement
            set DoICode = %s,
            Privilege = %i
            where CourseID = %i
            and UserID = %i
            ', $request['DoICode']
            , $request['Privilege']
            , $request['CourseID']
            , $getUID['ID']
            );
        }
        else
        {
             $affected = DB::insert('Involvement', [
            'CourseID' => $request['CourseID'],
            'UserID' => $getUID['ID'],
            'ExcusedAbsences' => 0,
            'DoICode' => $request['DoICode'],
            'Privilege' => $request['Privilege']
            ]);
        }       
        
        $response = [
            'status' => [
                'code' => 200,
                'msg' => 'involvement added'
            ]
        ];

        echo json_encode($response);
    }
?>
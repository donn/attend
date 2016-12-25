<?php

    //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';

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

    $necessary_fields = ['CourseID'];
    
    $request = $data['request'];

    if(!check_json_fields($request, $necessary_fields))
	{
		fail(400, 'malformed JSON request body');
	}


    //Authenticate
    $getInvolvement = DB::queryFirstRow(
		'SELECT *, count(*) as Count
		from Involvement
		where UserID = %i
		and CourseID = %i
		', $decoded->UID
		, $request['CourseID']);
    
    if (intval($getInvolvement['Count']) === 0)
    {
        fail(401, 'user not enrolled');
    }

    //Check if already request
    $getInvolvement = DB::queryFirstRow(
        'SELECT *
		from DropRequest
		where UserID = %i
		and CourseID = %i
		', $decoded->UID
		, $request['CourseID']);

    if ($getInvolvement['UserID'] !== null)
    {
        fail(400, 'drop already requested');
    }

    $confirmation = uniqid();

    $result = DB::query(
        'INSERT into DropRequest values
        (%i, %i, %s)
        ', $decoded->UID
		, $request['CourseID']
        , $confirmation
    );

    if ($result === array())
    {
        fail(500, 'failed to request drop');
    }

    $userInfo = DB::queryFirstRow(
        'SELECT *
        from User
        where ID = %i
        ',
        $decoded->UID
    );

    $courseInfo = DB::queryFirstRow(
        'SELECT *
        from Course
        where ID = %i
        ',
        $request['CourseID']
    );

    $professorsInfo = DB::query(
        'SELECT *
        from User
        where ID in
        (
            Select UserID
            from Involvement
            where DoICode = "P"
            and CourseID = %i
        )
        ',
        $request['CourseID']
    );

    require_once './lib/swift_required.php';
    $transport = Swift_SmtpTransport::newInstance('smtp.gmail.com', 465, "ssl")
    ->setUsername('teamminiattend@gmail.com')
    ->setPassword('');

    $mailer = Swift_Mailer::newInstance($transport);

    foreach ($professorsInfo as $professorInfo)
    {
        $emailBody = "Professor {$professorInfo['LastName']},
        
        {$userInfo['FirstName']} {$userInfo['LastName']} has requested to drop your course, {$courseInfo['Title']}.
        
        To approve the drop request:
        
        {$API_LINK}approve_drop.php?key={$confirmation}&action=approve
        
        To deny the drop request:
        
        {$API_LINK}approve_drop.php?key={$confirmation}
        
        
        team attend";            

        $message = Swift_Message::newInstance('attend Course Drop Request')
        ->setFrom(array('teamminiattend@gmail.com' => 'team attend'))
        ->setTo(array($professorInfo['RegistrationEmail']))
        ->setBody($emailBody);

        $result = $mailer->send($message);
    }      

    $response = [
            'status' => [
            'code' => 200
            , 'msg' => 'request sent']
            ];

    echo json_encode($response);

    die();
    


?>
<?php
    //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';


    $data = json_decode(file_get_contents('php://input'),true);

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

    $necessary_fields = ['QRString'];
    
    $request = $data['request'];

    if(!check_json_fields($request, $necessary_fields))
	{
		fail(400, 'malformed JSON request body');
	}
    
    //Get event instance
    $getEventInstance = DB::queryFirstRow(
        'SELECT *, count(*) as Count
        from EventInstanceExpanded
        where QRString = %s
        ', $request['QRString']
    );

    if (intval($getEventInstance['Count']) === 0)
    {
        fail(404, 'instance not found');
    }

    if ($getEventInstance['IsQRCodeActive'] == 'N')
    {
        fail(403, 'course inactive');
    }

    //Authenticate
    $getInvolvement = DB::queryFirstRow(
		'SELECT *, count(*) as Count
		from Involvement
		where UserID = %i
		and CourseID = %i
        and DoICode = "S"
		', $decoded->UID
		, $getEventInstance['CourseID']);

	if (intval($getInvolvement['Count']) === 0)
	{
		fail(401, 'not a student');
    }

    //Check if already attended
    $exist = DB::query(
        'SELECT count(*) as Count
        from Attendance
        where EventInstanceID = %i
        and UserID = %i
        ', $getEventInstance['ID']
        , $decoded->UID
    );

    if (intval($exist['Count']) !== 0)
	{
		fail(400, 'already attended');
    }


    //Attend
    $try = DB::query(
        'INSERT into Attendance values
            (%i, %i, %s)
        ', $getEventInstance['ID']
        , $decoded->UID
        , $getEventInstance['IsLate']
    );

    if ($try !== array())
    {
        $status = array('code'=>200,'msg'=>'created');
	    $success = array('status'=>$status);
	    echo json_encode($success);
    }
    else
    {
        fail(400, "failed to attend class");
    }

?>

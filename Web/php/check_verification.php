<?php

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

    $uid = $decoded->UID;

    $result = DB::queryFirstRow(
        'SELECT IsVerifiedProfessor, count(*) as Count
		FROM User
		WHERE ID = %i'
        , $uid);

    if(intval($result['Count']) === 0)
	{
        fail(500, 'user does not exist');
    }

	$response['VerifiedProfessor'] = ($result['IsVerifiedProfessor'] === 'Y')? true: false;

    $response = [
        'status' => [
            'code' => 200,
            'msg' => 'verified status of current user'
        ],
        'response' => $response
    ];

    echo json_encode($response);
?>
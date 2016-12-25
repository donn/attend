<?php
    //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';

    $data = json_decode(file_get_contents('php://input'),true);

    $necessary_fields = ['jwt'];
    
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

    $key = $JWT_KEY;

    $now = time();

    $token = [ 'iss' => $SERVER_LINK
			 // , 'aud' => $SERVER_LINK
			 , 'aud' => $email //Reciever
			 , 'iat' => $now //Time of Issuing
			 , 'nbf' => $now //Not Before
			 , 'exp' => $now + (3 * 24 * 60 * 60)
			 , 'UID' => $decoded->UID
			 ];

	$jwt = JWT::encode($token, $key);
	debug('jwt generated');
	JWT::$leeway = 60;
	$response = [ 'status' => [ 'code' => 200
							  , 'msg' => 'access token refreshed'
							  ]
				, 'jwt' => $jwt
				];

    echo json_encode($response);

?>
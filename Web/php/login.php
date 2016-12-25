<?php
	//Libraries
	require_once './lib/meekrodb.php';
	require_once './lib/jwt/JWT.php';
	use \Firebase\JWT\JWT;

	//Includes
	require_once './db_connect.php';
	require_once './utils.php';

	$login_data = file_get_contents('php://input');
	$login_data = json_decode($login_data, true);

	//Check request integrity
	$necessary_fields = ['email', 'password'];

	if($login_data === null || !check_json_fields($login_data, $necessary_fields))
		fail(400, 'malformed JSON request body');

	$email = $login_data['email'];
	$pass = $login_data['password'];

	$result = DB::queryFirstRow(
			'SELECT * FROM User WHERE RegistrationEmail=%s', $email
		);

	if($result === null || !password_verify($pass, $result['Password'])) {
		fail(401, 'wrong email or password');
	}

	//Verification passed
	$user_id = $result['ID'];

	DB::update('User', [
			'LastLoggedIn' => time()
			],
			'ID = %i', $user_id);

	$key = $JWT_KEY;

	$now = time();

	//Create token
	$token = [ 'iss' => $SERVER_LINK
			 // , 'aud' => $SERVER_LINK
			 , 'aud' => $email //Reciever
			 , 'iat' => $now //Time of Issuing
			 , 'nbf' => $now //Not Before
			 , 'exp' => $now + (3 * 24 * 60 * 60)
			 , 'UID' => $user_id
			 ];

	$jwt = JWT::encode($token, $key);
	debug('jwt generated');
	JWT::$leeway = 60;
	$response = [ 'status' => [ 'code' => 200
							  , 'msg' => 'access token attached'
							  ]
				, 'jwt' => $jwt
				];

	echo json_encode($response);
?>
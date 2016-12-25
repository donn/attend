<?php

	//Libraries
	require_once './lib/meekrodb.php';	
	require_once './lib/swift_required.php';

	//Includes
	require_once './utils.php';	
	require_once './db_connect.php';

	ini_set('display_errors', 1);
	ini_set('display_startup_errors', 1);
	
	//Check request integrity
	if(!isset($_GET['action']))
		fail(400, 'malformed request arguments');

	$action = $_GET['action'];

	$profile_data = json_decode(file_get_contents('php://input'), true);


	if($action !== 'verify' && $profile_data === null)
		fail(400, 'malformed JSON request body');

	debug('data received');
	
	//Creation
	if($action === 'new') {
		$necessary_fields =
			['fname', 'lname', 'email', 'password'];

		if(!check_json_fields($profile_data, $necessary_fields))
		{
			fail(400, 'malformed JSON request body');
		}

		$email = $profile_data['email'];

		//Check for existence in transient database
		$user_exists = DB::queryOneField('Email',
				'SELECT *
				FROM EmailConfirmation
				WHERE Email = %s
				AND RegisteredOn < (Select UNIX_TIMESTAMP()) + 86400;', $email // 86400 seconds = one day
			);
		if($user_exists !== null)
			fail(400, 'User pending verification');
		else
		{
			DB::query('DELETE FROM EmailConfirmation WHERE Email = %s;', $email); // Just to be sure it doesn't exist beyond this point.
		}

		debug('user looked up');

		//Check for existence in permanent database
		$user_exists = DB::queryOneField('RegistrationEmail',
				'SELECT * FROM User WHERE RegistrationEmail=%s', $email
			);
		if($user_exists !== null)
			fail(400, 'User already registered');

		$fname = $profile_data['fname'];
		$lname = $profile_data['lname'];
		$password = $profile_data['password'];
		$password = password_hash($password, PASSWORD_DEFAULT);
		$registered_on = time();

		// User profile data
		DB::insert('User', [
				'FirstName' => $fname,
				'LastName' => $lname,
				'RegistrationEmail' => null,
				'Password' => $password,
				'IsVerifiedProfessor' => 'N',
				'LastLoggedIn' => 0
			]);

		// User confirmation data
		$user_id = DB::insertId();
		$code = uniqid($email, true);
		DB::insert('EmailConfirmation', [
				'Email' => $email,
				'Code' => $code,
				'UserID' => $user_id,
				'RegisteredOn' => $registered_on
			]);

		debug('user added');

		$transport = Swift_SmtpTransport::newInstance('smtp.gmail.com', 465, "ssl")
		->setUsername('teamminiattend@gmail.com')
		->setPassword('');
		

		$emailBody = "Hello, {$fname}.
		
		You (or the ghost haunting your phone) has registered for an attend account.
		
		Just follow this link to complete your registration:
		
		{$API_LINK}register.php?action=verify&key={$code}
		
		If you didn't make this account, just ignore this email.
		
		Cheers!
		
		team attend
		
		";

		$mailer = Swift_Mailer::newInstance($transport);

		$message = Swift_Message::newInstance('Verify your attend account!')
		->setFrom(array('teamminiattend@gmail.com' => 'team attend'))
		->setTo(array($email))
		->setBody($emailBody);

		$result = $mailer->send($message);
		echo json_encode(
			[
				'status' => [
					'code' => 200,
					'msg' => 'user added; verification email sent'
				]
			]);
	}
	// Verification
	elseif ($action === 'verify')
	{
		if(!isset($_GET['key']))
			fail(400, 'malformed URL');

		$key = $_GET['key'];

		$result = DB::queryFirstRow(
			'SELECT * FROM EmailConfirmation WHERE Code = %s
			', $key
		);

		if($result === null) {
			// browser message
			header('Content-type: text/plain');
			// fail(400, 'verification key has expired');
			echo
				'<div> <p>',
					htmlspecialchars('<!> Verification key invalid or has expired.'),
				'</p> </div>';
			exit;
		}

		DB::queryFirstRow(
			'DELETE from EmailConfirmation
			where Code = %s
			', $key
		);

		DB::query(
			'UPDATE User
			SET RegistrationEmail = %s
			WHERE ID = %s
			', $result['Email']
			, $result['UserID']
			);

		$absentiacourses = DB::query(
			'SELECT *
			from StudentInAbsentia
			where Email = %s
			', $result['Email']
		);

		foreach ($absentiacourses as $absentiacourse)
		{
			DB::query(
			'INSERT into Involvement values
				(%i, %i, %s, %i, %i)
				', $result['UserID']
				, $absentiacourse['CourseID']
				, 'S', 0, 0
				);
		}

		// User verified:
		header('Content-type: text/html');
		echo
				'<div> <p>',
					htmlspecialchars('Verification successful.'),
				'</p> </div>';

	}
	// Internal; for explicitly canceling registration
	// elseif ($action === 'cancel') { //< Might delete

	// }
	else {
		fail(400, 'unknown action');
	}

?>

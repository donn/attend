<?php
/*
	attend php utils
*/
	header('Content-type: application/json');

	//Set error debugging on a file by file basis. Remember, it's an app reading that in the end. Not a human.
	ini_set('display_errors', 0);
	ini_set('display_startup_errors', 0);
	error_reporting(E_ALL);

	date_default_timezone_set('UTC'); 

	// Change to public address (and preferably a more secure key)
	$SERVER_LINK = 'YOUR_URL_HERE/';
	$API_LINK = $SERVER_LINK.'/php/';
	$WEBSITE_LINK = $SERVER_LINK.'/website/';
	$JWT_KEY = 'blah_blooh%bluh';

	/*
		Misc Functions
	*/
	function debug($msg) {
		if(false)
		{
			header('Content-type: text/plain');
			echo '<p>', htmlspecialchars($msg), '</p>';
		}
	}

	function fail($err_code = 500, $msg = '') {
		echo json_encode(
			[
				'status' => [ 'code' => $err_code, 'msg' => $msg ]
			]);
		http_response_code($err_code);
		die;
	}

	function respond($payload = [], $code = 200, $msg = '') {
		http_response_code($code);
		$response = [
			'status' => [
				'code' => $code,
				'msg' => $msg
			]
		];

		if(is_array($payload) && !empty($payload)) {
			$response = array_merge($response, [
				'response' => $payload
			]);
		}

		echo json_encode($response);
		die;
	}

	function rand_str($len = 32) {
		return
			base64_encode(openssl_random_pseudo_bytes($len * 4));
	}

	function validate_email_address($address) {
		return
			strpos($address, '@') !== FALSE && strpos($address, '.') !== FALSE;
	}

	function check_json_fields(&$json, &$fields) {
		$m_fields =
			!is_array($fields)
			? (array) $fields
			: $fields;

		foreach($m_fields as $f)
			if(!isset($json[$f]))
				return false;

		return true;
	}

	function bool_char($bool)
	{
		if ($bool)
		{
			return 'Y';
		}
		return 'N';
	}
	
	/*
		SQL Null Unwrap
		
		Use when something is nullable.
		Note that for this particular project, if a query is nullable, construct it out of meekroDB first using sprintf.
	*/
	function sql_null_unwrap($attribute) //-> String
	{
		if (is_null($attribute))
		{
			return 'null';
		}
		else
		{
			return strval($attribute);
		}
	}

	function sql_str_null_unwrap($string) //-> String
	{
		if (is_null($string))
		{
			return 'null';
		}
		else
		{
			return '"'.$string.'"';
		}
	}

?>

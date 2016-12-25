<?php

    //Libraries
    require_once './lib/meekrodb.php';
    require_once './lib/jwt/JWT.php';
    use \Firebase\JWT\JWT;

    //Includes
    require_once './utils.php';
    require_once './db_connect.php';

    header('Content-type: text/html');

    $data = json_decode(file_get_contents('php://input'),true);

    if(!isset($_GET['key']))
	{
        die("No confirmation code set.");
    }

    $key = $_GET['key'];

    //Check for existence
    $exist = DB::queryFirstRow(
				'SELECT *, count(*) as Count
				from DropRequest
				where ConfirmationString = %s
				', $key);

    if (intval($exist['Count']) === 0)
    {
       die("This key is either invalid or has expired.");
    }

    $deleteRequest = DB::query(
        'DELETE from DropRequest
        where ConfirmationString = %s
        ', $key
    );

    
    if ($_GET['action'] === 'approve')
    {
        $result = DB::query(
            'DELETE from Involvement
            where CourseID = %i
            and UserID = %i
            ', $exist['CourseID']
            , $exist['UserID']
        );

        die("Accepted the drop request.");
    }

    die("Denied the drop request.");    

?>
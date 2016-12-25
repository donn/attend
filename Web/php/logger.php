<?php

    function act_log($msg, $extra) {
        $msg = $msg !== null ? $msg : '';
        // $extra = $exrta !== null ? $extra : ''; 
        DB::insert('Log',
            [
                'Dt' => time(),
                'Msg' => $msg,
                'Extra' => $extra
            ]
        );

        /*
            CREATE TABLE Log (
                ID bigint AUTO_INCREMENT,
                Dt bigint not null,
                Msg text not null,
                Extra text null,
                PRIMARY KEY (ID)
            );

        */
    }

?>
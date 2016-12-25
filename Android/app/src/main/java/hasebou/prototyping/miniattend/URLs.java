package hasebou.prototyping.miniattend;

import com.android.volley.AuthFailureError;
import com.android.volley.NetworkError;
import com.android.volley.NoConnectionError;
import com.android.volley.ServerError;
import com.android.volley.TimeoutError;
import com.android.volley.VolleyError;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.Type;

/**
 * Created by karim hasebou on 07-Jul-16.
 */
public class URLs {
    public static final String BASE_URL = "YOUR_URL_HERE/php/";
    public static final String Login = BASE_URL +"/login.php";
    public static final String REGISTER = BASE_URL+"/register.php?action=new";
    public static final String GET_COURSES = BASE_URL+"/get.php?type=course";
    public static final String CREATE_COURSE = BASE_URL+"/create.php?type=course";
    public static final String CHECK_USER_STATUS = BASE_URL+"/check_verification.php";
    public static final String CREATE_EVENT = BASE_URL+"/create.php?type=event";
    public static final String CLASS_ATTENDENCE = BASE_URL+"/attend.php";
    public static final String DROP_COURSE = BASE_URL+"/drop_request.php";
    public static final String GET_EVENTS = BASE_URL + "/get.php?type=event";
    public static final String GET_EVENT_INSTANCES = BASE_URL+"/get.php?type=eventinstance";
    public static final String CREATE_EVENT_INSTANCE = BASE_URL+"/create.php?type=eventinstance";
    public static final String ALTER_INVOLVEMENT = BASE_URL+"/alter.php?type=involvement";
    public static final String CHECK_VERIFICATION = BASE_URL+"/check_verification.php";
    public static final String GET_UPCOMING_EVENT = BASE_URL+"/get_upcoming_event.php";
}

package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.EditText;

import com.afollestad.materialdialogs.MaterialDialog;
import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;

import me.zhanghai.android.materialprogressbar.MaterialProgressBar;

public class RegistrationActivity extends AppCompatActivity {
    private EditText firstNameEditText, lastNameEditText,passwordEditText,
            passwordConfirmEditText,emailEditText;
    private DataHolders.VerificationInfo userInfo =
            new DataHolders.VerificationInfo();
    private final boolean debug = false;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        HelperFunctions.initRequestQueue(getApplicationContext());
        login();
        setContentView(R.layout.activity_sign_up);

        initUi();
        if (this.debug)
        {
            Intent i = new Intent(this, MainActivity.class);
            startActivity(i);
        }
    }

    private void login() {
        SharedPreferences prefs = getSharedPreferences(getString(R.string.preferences),
                Context.MODE_PRIVATE);
        String token = prefs.getString(getString(R.string.login_token),null);

        if(token != null){
            startActivity(new Intent(this,MainActivity.class));
            finish();
        }
    }

    /**
     * initializes all ui elements
     */
    private void initUi(){
        firstNameEditText = (EditText) findViewById(R.id.sign_up_firstname);
        lastNameEditText = (EditText) findViewById(R.id.sign_up_lastname);
        passwordEditText = (EditText) findViewById(R.id.sign_up_password);
        emailEditText = (EditText) findViewById(R.id.sign_up_email);
        passwordConfirmEditText = (EditText) findViewById
                (R.id.sign_up_password_confirm);
    }

    private void enableFullScreen() {
        if (Build.VERSION.SDK_INT < 16) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN);
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_FULLSCREEN);
        }

        try {
            getSupportActionBar().hide();
        } catch (NullPointerException e) {
            //Whoops
        }
    }

    public void onClick_Signup(View view){
        userInfo.fname = firstNameEditText.getText().toString();
        userInfo.lname = lastNameEditText.getText().toString();
        userInfo.email = emailEditText.getText().toString();
        userInfo.password = passwordEditText.getText().toString();

        if(userInfo.fname.isEmpty() || userInfo.lname.isEmpty() || userInfo.password.isEmpty()
                || userInfo.email.isEmpty()){
            Snackbar.make(findViewById(android.R.id.content),
                    R.string.fields_empty,Snackbar.LENGTH_LONG).show();
        }else if(!userInfo.password.equals(passwordConfirmEditText.
                getText().toString()) ){
            Snackbar.make(findViewById(android.R.id.content),
                    R.string.password_unmatch,Snackbar.LENGTH_LONG).show();
        }else{
            HelperFunctions.showProgressBar(this,"Registering","Please wait");
            String request = (new Gson()).toJson(userInfo);
            submitCredentials(request);

        }
    }


    public void onClick_Login(View view){
        Intent i = new Intent(this, LoginActivity.class);
        startActivity(i);
    }

    private void submitCredentials(final String request){
        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.REGISTER,responseListener,errorListener){
            @Override
            public byte[] getBody() throws AuthFailureError {
                return request.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }

    private com.android.volley.Response.Listener<String> responseListener =
        new com.android.volley.Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
                HelperFunctions.hideProgessBar();

                Gson json = new Gson();
                Type type = new TypeToken<DataHolders.Response>(){}.getType();

                DataHolders.Response serverResponse =
                        json.fromJson(response,type);

                if(serverResponse.status.code != 200) {
                    showErrorDialog("Unknown error");
                }else{
                    Intent i = new Intent(RegistrationActivity.this,
                            LoginActivity.class);
                    startActivity(i);
                }
            }
        };

    private com.android.volley.Response.ErrorListener errorListener =
            new com.android.volley.Response.ErrorListener() {
        @Override
        public void onErrorResponse(VolleyError error) {
            HelperFunctions.hideProgessBar();
            String errorMsg = HelperFunctions.getError(error);

            View.OnClickListener onClickListener = new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    final String jsonRequest = (new Gson()).toJson(userInfo);
                    submitCredentials(jsonRequest);
                }
            };

            Snackbar.make(findViewById(android.R.id.content),
                    errorMsg,Snackbar.LENGTH_LONG).
                    setAction("Try Again",onClickListener).show();
        }
    };

    public void showErrorDialog(String errorMsg){
        View.OnClickListener onClickListener = new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                final String jsonRequest = (new Gson()).toJson(userInfo);
                submitCredentials(jsonRequest);
            }
        };

        Snackbar.make(findViewById(android.R.id.content),
                R.string.conn_error ,Snackbar.LENGTH_LONG).
                setAction(errorMsg,onClickListener).show();
    }
}

package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.EditText;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;

public class LoginActivity extends AppCompatActivity {
    private EditText editTextEmail;
    private EditText editTextPassword;
    private DataHolders.VerificationInfo userInfo;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        editTextEmail = (EditText) findViewById(R.id.login_email);
        editTextPassword = (EditText) findViewById(R.id.login_password);
    }

    /**
     * submits credentials to server for authentication
     * @param view login button
     */
    public void onClick(View view){
        String email = editTextEmail.getText().toString();
        String password = editTextPassword.getText().toString();

        if(email.isEmpty() || password.isEmpty()){
            Snackbar.make(findViewById(android.R.id.content),
                    R.string.fields_empty, Snackbar.LENGTH_LONG).show();
        }else{
            userInfo = new DataHolders.VerificationInfo(email, password);
            submitCredentials((new Gson()).toJson(userInfo));
        }
    }



    private void submitCredentials(final String request){
        HelperFunctions.showProgressBar(this,"Signing in","Please wait");
        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.Login,responseListener,errorListener){
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

            SharedPreferences prefs = getSharedPreferences(getString(R.string.preferences),
                    Context.MODE_PRIVATE);
            prefs.edit().putString(getString(R.string.login_token),serverResponse.jwt).commit();

            startActivity(new Intent(LoginActivity.this,MainActivity.class));
            finish();
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
}

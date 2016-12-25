package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.support.design.widget.Snackbar;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Toast;

import com.android.volley.Request;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;

public class ChangeInvolvementActivity extends AppCompatActivity {
    private EditText email;
    private Spinner privilagesSpinner,involvementSpinner;
    private String courseID;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_involvement);

        ActionBar actionBar = getSupportActionBar();
        actionBar.setDisplayHomeAsUpEnabled(true);

        email = (EditText) findViewById(
                R.id.activity_change_involvement_email);
        privilagesSpinner = (Spinner) findViewById(
                R.id.activity_change_involvement_privileges);
        involvementSpinner = (Spinner) findViewById(
                R.id.activity_change_involvement_title);

        courseID = getIntent().getStringExtra(ClassStatsActivity.COURSE_ID);
    }


    public void changeInvolvement(View view){
        //['UserID', 'CourseID', 'DoICode', 'Privilege'];

        HelperFunctions.showProgressBar(this,"Saving changes","Please wait");

        DataHolders.AlterInvolvement course = new DataHolders.AlterInvolvement();
        course.CourseID = courseID;
        course.Email = email.getText().toString();

        switch (involvementSpinner.getSelectedItemPosition()){
            case 0: // professor
                course.DoICode = "P";
                break;
            case 1: // senior ta
                course.DoICode = "ST";
                break;
            case 2:
                course.DoICode = "TA";
                break;
            case 3:
                course.DoICode = "S";
                break;
        }

        course.Privilege = String.valueOf(
                privilagesSpinner.getSelectedItemPosition());

        final String request = DataHolders.wrapInJWT(new Gson().toJson(course)
                ,this);

        Log.e("request involvement",request);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.ALTER_INVOLVEMENT,responseListener,errorListener){
            @Override
            public byte[] getBody(){
                return request.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()){
            case android.R.id.home:
                onBackPressed();    //Call the back button's method
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private com.android.volley.Response.Listener<String> responseListener =
            new com.android.volley.Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    HelperFunctions.hideProgessBar();
                    Toast.makeText(ChangeInvolvementActivity.this,
                            "Changes made",Toast.LENGTH_LONG).show();
                    finish();
                }
            };

    private com.android.volley.Response.ErrorListener errorListener =
            new com.android.volley.Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError serverError) {
                    HelperFunctions.hideProgessBar();
                    String error = HelperFunctions.getError(serverError);
                    Toast.makeText(ChangeInvolvementActivity.this,
                            error,Toast.LENGTH_LONG).show();
                }
            };
}

package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.support.design.widget.Snackbar;
import android.support.v4.app.NavUtils;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.FieldNamingPolicy;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;

public class CreateClassActivity extends AppCompatActivity {
    private TextView courseName,courseCode,
            courseSection,courseAllowedAbsences;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create_class);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        courseName = (TextView) findViewById(R.id.class_create_name);
        courseCode = (TextView) findViewById(R.id.class_create_code);
        courseSection = (TextView) findViewById(R.id.class_create_section);
        courseAllowedAbsences = (TextView) findViewById(
            R.id.class_create_allowed_absences);

    }

    public void onClickCreateClass(View view){
        String name = courseName.getText().toString();
        String code = courseCode.getText().toString();
        String section = courseSection.getText().toString();
        String allowedAbsences = courseSection.getText().toString();

        if(!name.matches(".+")){
            Toast.makeText(this,"Course name field cannot be empty",
                    Toast.LENGTH_SHORT).show();
            return;
        }

        DataHolders.Course mCourses
                = new DataHolders.Course();

        mCourses.Title = name;
        if(!code.isEmpty())
            mCourses.Code = code;
        if(!section.isEmpty())
            mCourses.Section =  section;
        if(!allowedAbsences.isEmpty())
            mCourses.MissableEvents = allowedAbsences;


        SharedPreferences prefs = getSharedPreferences(getString(R.string.preferences),
                Context.MODE_PRIVATE);
        prefs.getString(getString(R.string.login_token),null);

        String request = new Gson().toJson(mCourses);
        request = DataHolders.wrapInJWT(request,this);

        Log.i("json request",request);

        final String finalRequest = request;
        StringRequest mStringRequest = new StringRequest(Request.Method.POST,URLs.CREATE_COURSE,
                responseListener,errorListener){
            @Override
            public byte[] getBody(){
                return finalRequest.getBytes();
            }
        };
        HelperFunctions.addRequest(mStringRequest);
    }


    private Response.Listener<String> responseListener =
            new Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    Toast.makeText(CreateClassActivity.this,"Class created",Toast.LENGTH_LONG).show();
                    NavUtils.navigateUpFromSameTask(CreateClassActivity.this);
                }
            };

    private Response.ErrorListener errorListener =
            new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    String errorMsg = HelperFunctions.getError(error);

                    Toast.makeText(CreateClassActivity.this,
                            errorMsg,Toast.LENGTH_LONG).show();
                }
            };
}

package hasebou.prototyping.miniattend;

import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.support.v7.widget.SwitchCompat;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.DatePicker;
import android.widget.TextView;
import android.widget.TimePicker;
import android.widget.Toast;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.google.gson.Gson;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

public class CreateEventInstance extends AppCompatActivity
        implements DatePickerDialog.OnDateSetListener, TimePickerDialog.OnTimeSetListener {

    public  static final String TIME = "TIME";
    private Calendar calendar;
    private SwitchCompat mSwitchCompat;
    private DatePickerDialog datePickerDialog;
    private TimePickerDialog timePickerDialog;
    private TextView instanceTime,instanceDate;
    private DataHolders.Event event;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create_event_instance);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);


        calendar = Calendar.getInstance();
        event = (DataHolders.Event) getIntent().
                getSerializableExtra(EventListActivity.EVENT);

        initUI();
    }


    public void selectDate(View view){
        datePickerDialog.show();
    }

    public void selectTime(View view){
        timePickerDialog.show();
    }

    public void createInstance(View view){
        HelperFunctions.showProgressBar(this,"Creating Session","Please wait");
        DataHolders.EventInstance eventInstance =
                    new DataHolders.EventInstance();

        eventInstance.EventID = Integer.parseInt(event.ID);
        eventInstance.QRCodeActive = mSwitchCompat.isChecked();
        eventInstance.StartTime = String.valueOf(
                calendar.getTime().getTime()/1000);

        final String request = DataHolders.wrapInJWT(
                new Gson().toJson(eventInstance),this);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.CREATE_EVENT_INSTANCE,responseListener,errorListener){
          @Override
            public byte[] getBody(){
              return  request.getBytes();
          }
        };

        HelperFunctions.addRequest(mStringRequest);
    }


    private com.android.volley.Response.Listener<String> responseListener =
            new com.android.volley.Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    Toast.makeText(CreateEventInstance.this,
                            "Session Created",Toast.LENGTH_LONG).show();
                    HelperFunctions.hideProgessBar();
                    finish();
                }
            };

    private Response.ErrorListener errorListener = new Response.ErrorListener() {
        @Override
        public void onErrorResponse(VolleyError error) {
            String strError = HelperFunctions.getError(error);
            Toast.makeText(CreateEventInstance.this,
                    strError,Toast.LENGTH_LONG).show();
            HelperFunctions.hideProgessBar();
        }
    };

    public void initUI(){
       // Calendar calendar = Calendar.getInstance();
        int hour,minute;

        mSwitchCompat = (SwitchCompat) findViewById(R.id.code_active);
        instanceTime = (TextView) findViewById(R.id.event_instance_time);
        instanceDate = (TextView) findViewById(R.id.event_instance_date);


        if(event.TypicalStartTime == null){
            hour = calendar.get(Calendar.HOUR_OF_DAY);
            minute = calendar.get(Calendar.MINUTE);

            SimpleDateFormat time = new SimpleDateFormat("HH:mm:ss");

            instanceTime.setText(time.format(new Date() ));
        }else{
            String[] time = event.TypicalStartTime.split(":");
            hour = Integer.parseInt(time[0]);
            minute = Integer.parseInt(time[1]);

            instanceTime.setText(String.format("%02d:%02d",hour,minute));
        }

        datePickerDialog = new DatePickerDialog(this,this,
            calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),Calendar.DAY_OF_MONTH);
        timePickerDialog = new TimePickerDialog(this,this,hour,minute,true);

        instanceDate.setText(new SimpleDateFormat("yyyy-MM-dd").format(new Date()));
    }

    @Override
    public void onDateSet(DatePicker datePicker,
                int year, int month, int day) {
        calendar.set(year,month,day);
        instanceDate.setText(new SimpleDateFormat("yyyy-MM-dd")
                        .format(calendar.getTime()));
    }

    @Override
    public void onTimeSet(TimePicker timePicker, int hour,int minute) {
        calendar.set(Calendar.HOUR_OF_DAY,hour);
        calendar.set(Calendar.MINUTE,minute);
        calendar.set(Calendar.SECOND,0);

        instanceTime.setText(new SimpleDateFormat("HH:mm:ss")
                .format(calendar.getTime()));
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
}

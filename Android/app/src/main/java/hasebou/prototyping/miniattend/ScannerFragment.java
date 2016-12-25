package hasebou.prototyping.miniattend;


import android.Manifest;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.support.design.widget.Snackbar;
import android.support.v4.app.ActivityCompat;
import android.support.v4.app.Fragment;
import android.support.v7.app.AlertDialog;
import android.text.InputType;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.afollestad.materialdialogs.MaterialDialog;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


/**
 * A simple {@link Fragment} subclass.
 */
public class ScannerFragment extends Fragment
        implements BarcodeTrackerFactory.QRDetectedListener,MenuItemListener {
    private MaterialDialog progressDialog = null;
    private CameraController mCameraController;
    public static final int CAMERA_REQUEST = 1;
    private View mView;



    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        mView =  inflater.inflate(R.layout.fragment_scanner,
                container, false);

        mCameraController = (CameraController)
                mView.findViewById(R.id.camera_controller);
        mCameraController.setListener(this);
        return mView;
    }

    @Override
    public void onStart(){
        super.onStart();
        requestCameraPermission();
        loadNextClass();
    }

    private void loadNextClass() {
        final String request = DataHolders.wrapInJWT("{}",getContext());

        StringRequest mStringRequest  = new StringRequest(Request.Method.POST,
                URLs.GET_UPCOMING_EVENT, new Response.Listener<String>(){
            @Override
            public void onResponse(String response) {
                DataHolders.EventWrapper event = new Gson().fromJson(
                        response, DataHolders.EventWrapper.class);

                TextView classTitle = ((TextView) mView.findViewById(R.id.upcoming_class_title));
                TextView startTime = (TextView) mView.findViewById(R.id.upcoming_class_startime);


                if(event.response != null){
                    classTitle.setText(event.response.Title);
                    startTime.setText(event.response.TypicalStartTime);
                }else{
                    classTitle.setText("No classes coming up shortly");
                }
                Log.e("this is working",response);
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Log.e("scanner next class",HelperFunctions.getError(error));
            }
        }){
            @Override
            public byte[] getBody(){
                return request.getBytes();
            }
        };
        HelperFunctions.addRequest(mStringRequest);
    }

    @Override
    public void onResume() {
        super.onResume();
        if(isVisible())
            toggleCamera(true);
    }
/*
    @Override
    public void onPause() {
        super.onPause();
        mCameraController.stop();
    }*/

    @Override
    public void onStop(){
        super.onStop();
        mCameraController.release();
    }

    @Override
    public void onDetect(String value) {

        if(!value.matches("miniAttendCode:.*"))
            return;

       // mCameraController.stop();

        value = value.substring("miniAttendCode:".length());

        DataHolders.Attendance attendance = new DataHolders.Attendance();
        attendance.QRString = value;
        final String jsonRequest = DataHolders.wrapInJWT(
                new Gson().toJson(attendance),getContext());


        final StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.CLASS_ATTENDENCE,responseListener,errorListener){
            @Override
            public byte[] getBody(){
                return jsonRequest.getBytes();
            }
        };


        new AsyncTask<Void,Void,Void>(){
            @Override
            protected Void doInBackground(Void... voids) {
                return null;
            }

            @Override
            protected void onPostExecute(Void aVoid) {
                HelperFunctions.showProgressBar(ScannerFragment.this.getActivity()
                        ,"Signing attendance","Please wait");
            }
        }.execute();

        HelperFunctions.addRequest(mStringRequest);
    }

    private void requestCameraPermission(){
        // Should we show an explanation?
        if (ActivityCompat.shouldShowRequestPermissionRationale(getActivity(),
                Manifest.permission.CAMERA)) {

            new AlertDialog.Builder(getContext())
                    .setTitle("Camera permission")
                    .setMessage("Please enable camera permission to scan QR codes")
                    .setNeutralButton("dismiss", null)
                    .show();

        } else {

            // No explanation needed, we can request the permission.
            ActivityCompat.requestPermissions(getActivity(),
                    new String[]{Manifest.permission.READ_CONTACTS},
                    CAMERA_REQUEST);
        }
    }

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        toggleCamera(isVisibleToUser);
    }


    public void toggleCamera(boolean enable){
        if (enable) {
            if(mCameraController != null)
                mCameraController.start();
        }else {
            if(mCameraController != null) {
                mCameraController.stop();
            }
        }
    }

    public void notifyPermissionChanged(boolean enabled){
        if(enabled)
            mCameraController.start();
    }


    private void showPinDialog(){

        new MaterialDialog.Builder(getActivity())
                .title("Enter Qr Code")
                .content("Qr code value")
                .inputType(InputType.TYPE_CLASS_NUMBER )
                .input("ex..1234", "", new MaterialDialog.InputCallback() {
                    @Override
                    public void onInput(MaterialDialog dialog, CharSequence input) {
                        onDetect("miniAttendCode:"+input);
                    }
                }).show();
    }

    @Override
    public void onMenuOptionSelected(int id) {
        switch (id){
            case R.id.enter_pin:
                showPinDialog();
                break;
        }
    }

    private com.android.volley.Response.Listener<String> responseListener =
            new com.android.volley.Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    Toast.makeText(getContext(),"Attendance sign up complete"
                            ,Toast.LENGTH_LONG).show();
                    HelperFunctions.hideProgessBar();
                    mCameraController.start();
                }
            };

    private com.android.volley.Response.ErrorListener errorListener =
            new com.android.volley.Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    HelperFunctions.hideProgessBar();
                    Toast.makeText(getContext(),HelperFunctions.getError(error)
                            ,Toast.LENGTH_LONG).show();
                    mCameraController.start();
                }
            };
}

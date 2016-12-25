package hasebou.prototyping.miniattend;

import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import com.afollestad.materialdialogs.MaterialDialog;
import com.android.volley.AuthFailureError;
import com.android.volley.NetworkError;
import com.android.volley.NoConnectionError;
import com.android.volley.RequestQueue;
import com.android.volley.ServerError;
import com.android.volley.TimeoutError;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.Type;

import me.zhanghai.android.materialprogressbar.MaterialProgressBar;

/**
 * Created by auc on 7/19/16.
 */

public class HelperFunctions {
    private static RequestQueue mRequestQueue;
    private static MaterialDialog progressBarDialog;

    public static void initRequestQueue(Context context){
        mRequestQueue = Volley.newRequestQueue(context);
    }

    public static void addRequest(StringRequest stringRequest){
        mRequestQueue.add(stringRequest);
    }

    public static String getError(VolleyError error){
        String message;
        try {
            if (error instanceof NoConnectionError)
                message = "No internet connection";
          /*  else if (error instanceof ServerError) {
                message = "Server is unreachable";
                Log.e("Get error", new String(error.networkResponse.data, "UTF-8"));
            }*/else if (error instanceof TimeoutError){
                message = "Server timed out";
            }else if (error instanceof AuthFailureError || error instanceof ServerError){
                message = new String(error.networkResponse.data, "UTF-8");

                Gson json = new Gson();
                Type type = new TypeToken<DataHolders.Response>() {
                }.getType();

                DataHolders.Response serverResponse =
                        json.fromJson(message, type);

                message = serverResponse.status.msg;
            }else if (error instanceof NetworkError)
                message = "Network error";
            else
                message = "Unknown error";
        } catch (UnsupportedEncodingException e) {
            message =  "Unknown error";
        }
        return message;
    }

    public static String getToken(Context context){
        SharedPreferences prefs = context.getSharedPreferences(
                context.getString(R.string.preferences),
                Context.MODE_PRIVATE);
        return prefs.getString(context.getString(R.string.login_token),"");
    }

    public static void showProgressBar(Context context,String Title,String contentText) {
        progressBarDialog = new MaterialDialog.Builder(context)
                .content(contentText)
                .title(Title)
                .progress(true, 0).build();
        progressBarDialog.show();
    }

    public static void hideProgessBar(){
        if(progressBarDialog != null){
            progressBarDialog.dismiss();
            progressBarDialog = null;
        }
    }
}
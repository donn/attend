
package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.support.annotation.IdRes;
import android.support.design.widget.Snackbar;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.content.ContextCompat;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.roughike.bottombar.BottomBar;
import com.roughike.bottombar.OnMenuTabClickListener;

import java.lang.reflect.Type;

public class MainActivity extends AppCompatActivity {
    private Fragment[] fragments;
    private BottomBar navigationBar;
    private ViewPager mViewPager;
    private boolean isMenuVisible = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initUI(savedInstanceState);
        checkUserPrivileges();
    }


    private void checkUserPrivileges() {

        final String request = DataHolders.wrapInJWT("\"\"",this);
        Log.e("check user privileges",request);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.CHECK_USER_STATUS, new Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
                if(response.contains("true")){
                    isMenuVisible = true;
                    invalidateOptionsMenu();
                }
                Log.e("class Class stats ",response);
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Log.e("error",HelperFunctions.getError(error));
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
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);

        navigationBar.onSaveInstanceState(outState);
    }

    private void initUI(Bundle savedState){
        fragments = new Fragment[3];

        fragments[0] = new ScannerFragment();
        fragments[1] = new ClassesFragment();
        fragments[2] = new MoreFragment();



        mViewPager = (ViewPager) findViewById(R.id.main_activity_pager);
        mViewPager.setAdapter(fragmentPagerAdapter);

        navigationBar = BottomBar.attach(this,savedState);
        navigationBar.setMaxFixedTabs(fragments.length-1);
        navigationBar.setItems(R.menu.bottom_nav_bar);
        navigationBar.setOnMenuTabClickListener(navBarListener);

        navigationBar.mapColorForTab(0, ContextCompat.getColor(
                this, R.color.colorPrimaryDark));
        navigationBar.mapColorForTab(1, "#5D4037");
        navigationBar.mapColorForTab(2, "#FF5252");
        navigationBar.setDefaultTabPosition(0);

        mViewPager.addOnPageChangeListener(
            new ViewPager.SimpleOnPageChangeListener() {
                @Override
                public void onPageSelected(int position) {
                    navigationBar.selectTabAtPosition(position,true);
                    invalidateOptionsMenu();
                }
            });
    }

    OnMenuTabClickListener navBarListener = new OnMenuTabClickListener(){
        @Override
        public void onMenuTabSelected(@IdRes int menuItemId) {
            mViewPager.setCurrentItem(
                    navigationBar.getCurrentTabPosition());
        }

        @Override
        public void onMenuTabReSelected(@IdRes int menuItemId) {
        }
    };

    private FragmentPagerAdapter fragmentPagerAdapter =
            new FragmentPagerAdapter(getSupportFragmentManager()){
        @Override
        public Fragment getItem(int position) {
            return fragments[position];
        }

        @Override
        public int getCount() {
            return fragments.length;
        }
    };

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String permissions[], int[] grantResults) {
        switch (requestCode) {
            case ScannerFragment.CAMERA_REQUEST: {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    ((ScannerFragment)fragments[0]).notifyPermissionChanged(true);
                }
                return;
            }

            // other 'case' lines to check for other
            // permissions this app might request
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();

        switch (navigationBar.getCurrentTabPosition()){
            case 0:
                inflater.inflate(R.menu.qr_scanner_menu, menu);
                break;
            case 1:
                if(isMenuVisible)
                    inflater.inflate(R.menu.class_fragment_menu,menu);
                break;
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        int itemId = item.getItemId();
        switch (itemId) {
            case R.id.create_class:

                Intent intent = new Intent(this,CreateClassActivity.class);
                startActivity(intent);

                return true;
            case R.id.enter_pin:
                ((MenuItemListener)fragments[0]).
                        onMenuOptionSelected(itemId);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }


    private com.android.volley.Response.Listener<String> statusResponse =
            new com.android.volley.Response.Listener<String>() {
                @Override
                public void onResponse(String response) {

                }
            };

    private com.android.volley.Response.ErrorListener statusErrorResponse =
            new com.android.volley.Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    String errorMsg = HelperFunctions.getError(error);


                }
            };
}

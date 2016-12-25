package hasebou.prototyping.miniattend;


import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.v4.widget.SwipeRefreshLayout;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.TimePicker;
import android.widget.Toast;

import com.afollestad.materialdialogs.DialogAction;
import com.afollestad.materialdialogs.MaterialDialog;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.google.gson.Gson;

public class EventListActivity extends AppCompatActivity implements SwipeRefreshLayout.OnRefreshListener {
    private SwipeRefreshLayout mSwipeRefreshLayout;
    private DataHolders.Course mCourses = null;
    private DataHolders.EventList eventList = null;
    private ListView mListView;
    public static final String EVENT = "EVENT";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_event_list);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        mCourses = (DataHolders.Course) getIntent().
                getSerializableExtra(ClassesFragment.CLASS_INSTANCE);

        mSwipeRefreshLayout = ((SwipeRefreshLayout)
                findViewById(R.id.event_list_layout));
        mSwipeRefreshLayout.setOnRefreshListener(this);
        mListView = (ListView)
                findViewById(R.id.activity_event_list_view);
        mListView.setOnItemClickListener(listViewOnClick);
        mListView.setAdapter(mListAdapter);

        loadEvents();
    }



    public void loadEvents(){
        DataHolders.CourseIDWrapper wrapper
                = new DataHolders.CourseIDWrapper();
        wrapper.CourseID = mCourses.ID;

        final String request = DataHolders.wrapInJWT(
                new Gson().toJson(wrapper),this);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.GET_EVENTS,responseListener,errorListener){
            @Override
            public byte[] getBody(){
                return request.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }


    private com.android.volley.Response.Listener<String> responseListener =
            new com.android.volley.Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    eventList = new Gson().fromJson(response,
                            DataHolders.EventList.class);
                    mListAdapter.notifyDataSetChanged();

                    mSwipeRefreshLayout.setRefreshing(false);
                }
            };

    private com.android.volley.Response.ErrorListener errorListener =
            new com.android.volley.Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    String response = HelperFunctions.getError(error);

                    Toast.makeText(EventListActivity.this,
                            response,Toast.LENGTH_LONG).show();

                    mSwipeRefreshLayout.setRefreshing(false);
                }
            };


    private BaseAdapter mListAdapter = new BaseAdapter() {
        @Override
        public int getCount() {
            return eventList == null ? 0 : (eventList.response == null ?
                    0 : eventList.response.length);
        }

        @Override
        public Object getItem(int i) {
            return null;
        }

        @Override
        public long getItemId(int i) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup viewGroup) {
            ItemViewHolder viewHolder;

            if(convertView == null){
                LayoutInflater mInflater = LayoutInflater.from(EventListActivity.this);
                convertView = mInflater.inflate(R.layout.course_list_item,viewGroup,false);
                viewHolder = new ItemViewHolder(convertView);
                convertView.setTag(viewHolder);
            }

            DataHolders.Event event = eventList.response[position];
            viewHolder = (ItemViewHolder) convertView.getTag();
            viewHolder.title.setText(event.Title);

            viewHolder.subtitle.setText(event.TypicalStartTime);

            return convertView;
        }

        class ItemViewHolder{
            public TextView title,subtitle,rightText;

            public ItemViewHolder(View view){
                title = (TextView) view.findViewById(R.id.title);
                subtitle = (TextView) view.findViewById(R.id.subtitle);
                rightText = (TextView) view.findViewById(R.id.right_text);
            }
        }
    };

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.events_list_menu, menu);
        return true;
    }

    private void showEventCreator(){
        boolean wrapInScrollView = true;
        MaterialDialog.Builder dialogBuilder = new MaterialDialog.Builder(this)
                .title(R.string.create_event)
                .customView(R.layout.event_create, wrapInScrollView)
                .negativeText("Cancel")
                .positiveText(R.string.create);

        dialogBuilder.onPositive(new MaterialDialog.SingleButtonCallback() {
            @Override
            public void onClick(@NonNull MaterialDialog dialog, @NonNull DialogAction which) {
                View view = dialog.getCustomView();

                EditText eventNameEditText = (EditText)
                        view.findViewById(R.id.event_create_name);
                Spinner spinner = (Spinner) view.findViewById(
                        R.id.event_create_is_special);
                TimePicker timePicker = (TimePicker) view.findViewById(
                        R.id.event_create_time);

                createEvent(eventNameEditText.getText().toString(),
                        spinner.getSelectedItem().toString(),
                        timePicker.getCurrentHour(),timePicker.getCurrentMinute());
            }
        });

        MaterialDialog dialog = dialogBuilder.build();

        if(Integer.parseInt(mCourses.Privilege) == 1){
            Spinner spinner = (Spinner) dialog.getCustomView().findViewById(
                    R.id.event_create_is_special);
            spinner.setSelection(0);
            spinner.setEnabled(false);
        }

        dialog.show();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()){
            case R.id.class_stats_create_event:
                showEventCreator();
                return true;
            case android.R.id.home:
                onBackPressed();    //Call the back button's method
                return true;
        }
        return super.onOptionsItemSelected(item);
    }


    private void createEvent(String eventName,String isSpecial,
                             int hour,int minute){
        DataHolders.Event event =
                new DataHolders.Event(mCourses.ID,eventName,
                        isSpecial.charAt(0),hour,minute);

        final String eventJSON = DataHolders.wrapInJWT(new Gson().toJson(event),this);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.CREATE_EVENT, new Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
                Toast.makeText(EventListActivity.this,
                        "created",Toast.LENGTH_SHORT).show();
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError serverError) {
                String error = HelperFunctions.getError(serverError);
            }
        }){
            @Override
            public byte[] getBody(){
                return eventJSON.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }


    AdapterView.OnItemClickListener listViewOnClick =
            new AdapterView.OnItemClickListener() {
        @Override
        public void onItemClick(AdapterView<?> adapterView, View view,
                                int position, long id) {
            Intent intent = new Intent(EventListActivity.this,
                    CreateEventInstance.class);
            intent.putExtra(EVENT,eventList.response[position]);
            startActivity(intent);
        }
    };

    @Override
    public void onRefresh() {
        loadEvents();
    }
}

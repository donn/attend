package hasebou.prototyping.miniattend;

import android.os.Bundle;
import android.support.v4.widget.SwipeRefreshLayout;
import android.support.v7.app.AppCompatActivity;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.google.gson.Gson;

public class EventInstanceListActivity
      extends AppCompatActivity
      implements SwipeRefreshLayout.OnRefreshListener
{
  private SwipeRefreshLayout mSwipeRefreshLayout;
  private String courseID;
  private DataHolders.EventInstanceList eventInstanceList = null;
  private ListView mListView;


  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_event_instance_list);
    getSupportActionBar().setDisplayHomeAsUpEnabled(true);

    courseID = getIntent().getStringExtra(
            ClassStatsActivity.COURSE_ID);


    mSwipeRefreshLayout = ((SwipeRefreshLayout)
                                 findViewById(R.id.event_instance_list_layout));

    mSwipeRefreshLayout.setOnRefreshListener(this);

    mListView = (ListView) findViewById(
            R.id.activity_event_instance_list_view);

    mListView.setAdapter(mListAdapter);

    loadEventInstances();
  }

  public void loadEventInstances() {
    DataHolders.CourseIDWrapper wrapper
          = new DataHolders.CourseIDWrapper();
      wrapper.CourseID = courseID;

    final String request = DataHolders.wrapInJWT(new Gson().toJson(wrapper), this);
    StringRequest mStringRequest = new StringRequest(
          Request.Method.POST, URLs.GET_EVENT_INSTANCES, responseListener, errorListener) {
      @Override
      public byte[] getBody() {
        return request.getBytes();
      }
    };

    HelperFunctions.addRequest(mStringRequest);
  }

  private com.android.volley.Response.Listener<String> responseListener =
        new com.android.volley.Response.Listener<String>() {
          @Override
          public void onResponse(String response) {
            eventInstanceList = new Gson().fromJson(response, DataHolders.EventInstanceList.class);
            mListAdapter.notifyDataSetChanged();
            mSwipeRefreshLayout.setRefreshing(false);
          }
        };

  private Response.ErrorListener errorListener = new Response.ErrorListener() {
    @Override
    public void onErrorResponse(VolleyError error) {
      String response = HelperFunctions.getError(error);
      Toast.makeText(EventInstanceListActivity.this,
            response, Toast.LENGTH_LONG).show();

      mSwipeRefreshLayout.setRefreshing(false);
    }
  };

  private BaseAdapter mListAdapter = new BaseAdapter() {
    @Override
    public int getCount() {
      return eventInstanceList == null ? 0 : (eventInstanceList.response == null ?
                                                    0 : eventInstanceList.response.length);
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

      if (convertView == null) {
        LayoutInflater mInflater = LayoutInflater.from(EventInstanceListActivity.this);
        convertView = mInflater.inflate(R.layout.course_list_item, viewGroup, false);
        viewHolder = new ItemViewHolder(convertView);
        convertView.setTag(viewHolder);
      }

      DataHolders.EventInstance eventInstance = eventInstanceList.response[position];
      viewHolder = (ItemViewHolder) convertView.getTag();
      viewHolder.title.setText(eventInstance.Title != null ? eventInstance.Title : "No Title");

      viewHolder.subtitle.setText(eventInstance.StartTime);

      return convertView;
    }

    class ItemViewHolder {
      public TextView title, subtitle, rightText;

      public ItemViewHolder(View view) {
        title = (TextView) view.findViewById(R.id.title);
        subtitle = (TextView) view.findViewById(R.id.subtitle);
        rightText = (TextView) view.findViewById(R.id.right_text);
      }
    }
  };

    @Override
    public void onRefresh() {
    loadEventInstances();
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

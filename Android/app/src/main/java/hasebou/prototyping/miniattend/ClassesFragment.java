package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.widget.SwipeRefreshLayout;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.afollestad.materialdialogs.MaterialDialog;
import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;


public class ClassesFragment extends
        Fragment implements SwipeRefreshLayout.OnRefreshListener {
    public final static String CLASS_INSTANCE = "CLASS_INSTANCE";
    private SwipeRefreshLayout mSwipeRefreshLayout;
    private DataHolders.CoursesList mCoursesList = null;
    private ListView mListView;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();
        loadClasses();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view = inflater.inflate(
                R.layout.fragment_next_class, container, false);

        mListView = (ListView) view.findViewById(R.id.classes_list);
        mListView.setAdapter(mListAdapter);
        mListView.setOnItemClickListener(listClickListener);
        mListView.setOnItemLongClickListener(onLongClickListener);

        mSwipeRefreshLayout = (SwipeRefreshLayout) view.
                findViewById(R.id.next_class_layout);
        mSwipeRefreshLayout.setOnRefreshListener(this);
        mSwipeRefreshLayout.setColorSchemeResources(R.color.colorPrimaryDark,
                R.color.colorPrimary,R.color.colorAccent);

        return view;
    }

    private void loadClasses() {
        Context context = getContext();
        SharedPreferences prefs = context.getSharedPreferences(getString(R.string.preferences),
                Context.MODE_PRIVATE);
        String token = prefs.getString(getString(R.string.login_token),null);
        final String request = String.format("{\"jwt\":\"%s\"}",token);

        Log.d("load class request",request);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.GET_COURSES,responseListener,errorListener){
            @Override
            public byte[] getBody() throws AuthFailureError {
                return request.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }


    private Response.Listener<String> responseListener =
            new Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    Gson json = new Gson();
                    Type type = new TypeToken<DataHolders.
                            CoursesList>(){}.getType();
                        Log.e("get response",response);

                    mCoursesList  = json.fromJson(response,type);
                   mListAdapter.notifyDataSetChanged();

                   mSwipeRefreshLayout.setRefreshing(false);
                }
            };

    private Response.ErrorListener errorListener =
            new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    String errorMsg = HelperFunctions.getError(error);

                    Toast.makeText(getContext(),errorMsg,Toast.LENGTH_LONG).show();

                    mSwipeRefreshLayout.setRefreshing(false);
                }
            };

    private AdapterView.OnItemClickListener listClickListener =
            new AdapterView.OnItemClickListener() {
        @Override
        public void onItemClick(AdapterView<?> adapterView, View view, int position, long id) {
            Intent intent = new Intent(getActivity(),ClassStatsActivity.class);
            intent.putExtra(CLASS_INSTANCE,mCoursesList.response[position]);

            startActivity(intent);
        }
    };

    private AdapterView.OnItemLongClickListener onLongClickListener =
            new AdapterView.OnItemLongClickListener() {
                @Override
        public boolean onItemLongClick(AdapterView<?> adapterView,
                                       View view, final int position, long id) {

            new MaterialDialog.Builder(getContext())
                    .items(R.array.class_options)
                    .itemsCallback(new MaterialDialog.ListCallback() {
                        @Override
                        public void onSelection(MaterialDialog dialog, View view, int which, CharSequence text) {
                            dropCourse(position);
                        }
                    }).negativeText("Dismiss").show();
            return true;
        }
    };

    private void dropCourse(int courseIndex){
        DataHolders.CourseIDWrapper dropClass =
                new DataHolders.CourseIDWrapper();
        dropClass.CourseID = mCoursesList.response[courseIndex].ID;

        final String request = DataHolders.wrapInJWT(new Gson().
                toJson(dropClass),getContext());

        Log.i("Drop request",request);

        StringRequest mStringRequest = new StringRequest(Request.Method.POST,
                URLs.DROP_COURSE, new Response.Listener<String>() {

            @Override
            public void onResponse(String response) {
                Log.e("Success dropping",response);
                Toast.makeText(ClassesFragment.this.getActivity(),
                        "Drop request sent",Toast.LENGTH_LONG).show();
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Toast.makeText(ClassesFragment.this.getActivity(),
                        "Failed to send drop request",Toast.LENGTH_LONG).show();
                Log.e("Hello word",HelperFunctions.getError(error));
            }
        }){
            @Override
            public byte[] getBody(){
                return request.getBytes();
            }
        };

        HelperFunctions.addRequest(mStringRequest);
    }


    private BaseAdapter mListAdapter = new BaseAdapter() {
        @Override
        public int getCount() {
            return mCoursesList == null ? 0 : mCoursesList.response.length;
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
                LayoutInflater mInflater = LayoutInflater.from(getContext());
                convertView = mInflater.inflate(R.layout.course_list_item,viewGroup,false);
                viewHolder = new ItemViewHolder(convertView);
                convertView.setTag(viewHolder);
            }

            DataHolders.Course course = mCoursesList.response[position];
            viewHolder = (ItemViewHolder) convertView.getTag();
            viewHolder.title.setText(course.Title);

            if(course.PeopleOfInterest.length > 0) {
                StringBuilder builder = new StringBuilder();
                builder.append(course.PeopleOfInterest[0].FirstName);
                builder.append(" ");
                builder.append(course.PeopleOfInterest[0].LastName);

                viewHolder.subtitle.setText(builder.toString());
            }

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
    public void onRefresh() {
        loadClasses();
    }

}

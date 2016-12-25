package hasebou.prototyping.miniattend;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.mikhaellopez.circularprogressbar.CircularProgressBar;

import java.util.ArrayList;
import java.util.List;


public class ClassStatsActivity extends AppCompatActivity {
    public static final String COURSE_ID = "COURSE_ID";
    private DataHolders.Course mCourse;
    private TextView attendedText,excusedText,absentText;
    private CircularProgressBar mProgressBar;

    private ListView mListView;
    private ArrayAdapter<String> mAdapter;
    private List<String> peopleOfInterest;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_class_stats);

        ActionBar actionBar = getSupportActionBar();
        actionBar.setDisplayHomeAsUpEnabled(true);

        mCourse = (DataHolders.Course) getIntent().getSerializableExtra(
                ClassesFragment.CLASS_INSTANCE);

        actionBar.setTitle(mCourse.Title);

        attendedText = (TextView) findViewById(R.id.attended_classes);
        excusedText = (TextView) findViewById(R.id.excused_classes);
        absentText = (TextView) findViewById(R.id.absent_classes);
        mProgressBar = (CircularProgressBar) findViewById(R.id.attendance_progress);

        peopleOfInterest = new ArrayList<>();
        mAdapter = new ArrayAdapter<String>(this,android.R.
                layout.simple_list_item_1,peopleOfInterest);

        mListView = (ListView) findViewById(R.id.class_stats_list);
        mListView.setAdapter(mAdapter);

        showStats();
    }


    private void showStats(){
        if(mCourse == null)
            return;

        int totalClasses = mCourse.TotalEvents;
        int attended = Integer.parseInt(mCourse.AttendedEvents);
        int excused = Integer.parseInt(mCourse.ExcusedAbsences);

        attendedText.setText("Attended:\t"+mCourse.AttendedEvents);
        excusedText.setText("Excused:\t"+mCourse.ExcusedAbsences);
        absentText.setText("Absent:\t"+(totalClasses-attended));


        if(totalClasses == 0)
            mProgressBar.setProgressWithAnimation(100); // Default duration = 1500ms(5);
        else
            mProgressBar.setProgressWithAnimation((int)
                    ((double)attended)/totalClasses*100);

        for(DataHolders.PeopleOfInterest person : mCourse.PeopleOfInterest){
            peopleOfInterest.add(person.FirstName+" "+person.LastName);
        }

        mAdapter.notifyDataSetChanged();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        if(Integer.parseInt(mCourse.Privilege) >= 1)
            inflater.inflate(R.menu.class_stats_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        Intent intent;
        switch (item.getItemId()) {
            case R.id.class_stats_view_events:

                intent = new Intent(this
                        ,EventListActivity.class);
                intent.putExtra(ClassesFragment.CLASS_INSTANCE,
                        mCourse);
                startActivity(intent);
                return true;
            case R.id.class_stats_view_event_instance:
                intent = new Intent(this
                        ,EventInstanceListActivity.class);
                intent.putExtra(ClassStatsActivity.COURSE_ID,
                        mCourse.ID);
                startActivity(intent);
                return true;
            case R.id.change_involvment:
                intent = new Intent(this,
                        ChangeInvolvementActivity.class);
                intent.putExtra(COURSE_ID,mCourse.ID);
                startActivity(intent);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }
}




package hasebou.prototyping.miniattend;


import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.Preference;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;


/**
 * A simple {@link Fragment} subclass.
 */
public class MoreFragment extends Fragment {
    private Button logOut;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view =  inflater.inflate(R.layout.fragment_more, container, false);

        logOut = (Button) view.findViewById(R.id.log_out);
        logOut.setOnClickListener(logOutListener);
        return view;
    }

    private View.OnClickListener logOutListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            SharedPreferences prefs = getContext().getSharedPreferences(
                    getString(R.string.preferences), Context.MODE_PRIVATE);
            prefs.edit().remove(getString(R.string.login_token)).commit();

            Intent intent = new Intent(getActivity()
                    ,LoginActivity.class);
            startActivity(intent);
            getActivity().finish();
        }
    };

}

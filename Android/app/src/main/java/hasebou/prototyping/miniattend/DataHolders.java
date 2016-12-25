package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.SharedPreferences;

import java.io.Serializable;

/**
 *
 * contains all classes that will be used for server communication
 */
public class DataHolders{

    public static class VerificationInfo implements Serializable{
        public String fname;
        public String lname;
        public String email;
        public String password;

        public VerificationInfo() {
        }

        public VerificationInfo(String fname, String lname, String email, String password) {
            this.fname = fname;
            this.lname = lname;
            this.email = email;
            this.password = password;
        }

        public VerificationInfo(String email, String password) {
            this.email = email;
            this.password = password;
        }
    }

    public static class Response implements Serializable{
        public Status status;
        public String jwt;
    }

    public static class Status implements Serializable{
        public Integer code;
        public String msg;
    }

    public static class PeopleOfInterest implements Serializable{
        public String Email;
        public String FirstName;
        public String LastName;
        public String DoICode;
    }

    public static class Course implements Serializable
    {
        public String Title = null;; // introduced only because of inconsistency of api
        public String Section = null;;
        public Integer TotalEvents = null;
        public String MissableEvents = null;
        public String ExcusedAbsences = null;
        public String AttendedEvents = null;

        public PeopleOfInterest[] PeopleOfInterest = null;;

        public String Privilege = null;
        public String ID = null;
        public String DoI = null;
        public String Code = null;
    }

    public static class AlterInvolvement implements Serializable{
        public String CourseID;
        public String DoICode;
        public String Privilege;
        public String Email;
    }


    public static class CoursesList implements Serializable
    {
        public Course[] response;
        public Status status;
    }

    /**
     * adds jwt to the json request
     * @param jsonRequest
     * @return
     */
    public static String wrapInJWT(String jsonRequest,Context context){
        SharedPreferences prefs = context.getSharedPreferences(context.
                getString(R.string.preferences),
                Context.MODE_PRIVATE);
        String token = prefs.getString(context.getString(R.string.login_token),null);

        String wrap = String.format("{\"jwt\":\"%s\",\"request\":%s}",token,jsonRequest);
        return wrap;
    }

    public static class EventList implements Serializable{
        public Event[] response;
    }

    public static class EventWrapper{
        public Status status;
        public Event response;
    }


    public static class Event implements Serializable{
        public String ID;
        public String CourseID;
        public String Title;
        public boolean Special;
        public String TypicalStartTime;

        public Event(String courseID, String title, char special,
                     int hour, int minute) {
            this.CourseID = courseID;
            this.Title = title;
            this.Special = (special == 'Y');
            TypicalStartTime = String.format("%2d:%2d:00", hour, minute);
        }

        public Event(String ID, String courseID, String title,
                     boolean special, String typicalStartTime) {
            this.ID = ID;
            CourseID = courseID;
            Title = title;
            Special = special;
            TypicalStartTime = typicalStartTime;
        }
    }

    public static class EventInstanceList implements Serializable{
        public EventInstance[] response;
    }

    public static class EventInstance implements Serializable{
        public EventInstance(int ID, int eventID,
                             String startTime, String QRString,
                             boolean QRCodeActive, boolean isLate) {
            this.ID = ID;
            EventID = eventID;
            StartTime = startTime;
            this.QRString = QRString;
            this.QRCodeActive = QRCodeActive;
            IsLate = isLate;
        }

        public EventInstance() {
        }

        public int ID;
        public int EventID;
        public String StartTime;
        public String QRString;
        public boolean QRCodeActive;
        public boolean IsLate;
        public int CourseID;
        public String Title;
        public int UnixStartTime;
    }

    public static class CourseIDWrapper implements Serializable{
        public String CourseID;
    }

    public static class Attendance implements Serializable{
        public String QRString;
    }
}

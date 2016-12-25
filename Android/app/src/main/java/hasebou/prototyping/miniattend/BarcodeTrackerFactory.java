package hasebou.prototyping.miniattend;

import com.google.android.gms.vision.MultiProcessor;
import com.google.android.gms.vision.Tracker;
import com.google.android.gms.vision.barcode.Barcode;

/**
 * Created by karim hasebou on 08-Jul-16.
 */
class BarcodeTrackerFactory implements MultiProcessor.Factory<Barcode> {
    private QRDetectedListener listener = null;

    public interface QRDetectedListener{
         void onDetect(final String value);
    }

    public void setListener(QRDetectedListener listener) {
        this.listener = listener;
    }

    @Override
    public Tracker<Barcode> create(Barcode barcode) {
        if(barcode.rawValue != null && listener != null)
            listener.onDetect(barcode.rawValue);
        return new Tracker<Barcode>();
    }

}
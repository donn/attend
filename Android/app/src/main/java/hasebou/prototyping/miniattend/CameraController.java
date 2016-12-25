package hasebou.prototyping.miniattend;

import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.Camera;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AlertDialog;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.google.android.gms.tasks.RuntimeExecutionException;
import com.google.android.gms.vision.CameraSource;
import com.google.android.gms.vision.MultiProcessor;
import com.google.android.gms.vision.barcode.Barcode;
import com.google.android.gms.vision.barcode.BarcodeDetector;

import java.io.IOException;
import java.util.List;

/**
 * Created by karim hasebou on 14-Jul-16.
 */
public class CameraController extends SurfaceView implements
        SurfaceHolder.Callback {
    private BarcodeTrackerFactory barcodeFactory;
    private BarcodeDetector detector;
    private SurfaceHolder surfaceHolder = null;
    private CameraSource cameraSource = null;
    private Context context;
    private boolean startPreview = false;

    public CameraController(Context context) {
        super(context);
        this.context = context;

        initDecoder();
    }

    public CameraController(Context context, AttributeSet attrs) {
        super(context, attrs);
        this.context = context;

        initDecoder();
    }

    private void initDecoder(){
        detector = new BarcodeDetector.Builder(context).
                setBarcodeFormats(Barcode.QR_CODE).build();
        barcodeFactory = new
                BarcodeTrackerFactory();
        detector.setProcessor(
                new MultiProcessor.Builder<>(barcodeFactory).build());

        getHolder().addCallback(this);
    }

    private void prepareCamera(){

        CameraSource.Builder builder = new CameraSource.Builder(context, detector)
                .setFacing(CameraSource.CAMERA_FACING_BACK)
                .setRequestedFps(15.0f).setAutoFocusEnabled(true);

        builder.setRequestedPreviewSize(getWidth(),
                    getHeight());

        builder.setAutoFocusEnabled(true);
        cameraSource = builder.build();
    }

    public void start() {
        try{
            if (surfaceHolder == null){
                startPreview = true;
            }else if(cameraSource == null && ActivityCompat.checkSelfPermission(getContext(),
                    android.Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED){
                prepareCamera();
                cameraSource.start(surfaceHolder);
            }else if(cameraSource != null){
                cameraSource.start(surfaceHolder);
            }
        }catch (RuntimeExecutionException e){
            showDialog("Camera Not available",
                    "Camera might be in use by another application");
            cameraSource = null;
        } catch (IOException e) {
            showDialog("Error","Cannot show video preview");
        }
    }

    private void showDialog(String title,String message) {
        new AlertDialog.Builder(getContext())
                .setTitle(title).setMessage(message)
                .setNeutralButton("dismiss", null)
                .show();
    }

    public void stop(){
        if(cameraSource != null)
            cameraSource.stop();
    }

    public void release(){
        if(cameraSource != null) {
            cameraSource.release();
            cameraSource = null;
        }
    }

    public void setListener(BarcodeTrackerFactory.
            QRDetectedListener listener){
        barcodeFactory.setListener(listener);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        this.surfaceHolder = holder;
        if(startPreview){
            startPreview = false;
            start();
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder,
                               int format, int width, int height) {
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        this.surfaceHolder = null;
    }

    private Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio=(double)h / w;

        if (sizes == null) return null;

        Camera.Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;

        int targetHeight = h;

        for (Camera.Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - targetHeight) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - targetHeight);
            }
        }

        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Camera.Size size : sizes) {
                if (Math.abs(size.height - targetHeight) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - targetHeight);
                }
            }
        }
        return optimalSize;
    }

}

package hiflying.blelink.demo;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.location.LocationManager;
import android.net.wifi.WifiInfo;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;

import com.alibaba.fastjson.JSON;
import hiflying.blelink.HFLog;
import hiflying.blelink.LinkedModule;
import hiflying.blelink.LinkingError;
import hiflying.blelink.LinkingProgress;
import hiflying.blelink.OnLinkListener;
import hiflying.blelink.v1.BleLinker;

import java.text.SimpleDateFormat;
import java.util.Date;

import androidx.annotation.NonNull;

import permissions.dispatcher.NeedsPermission;
import permissions.dispatcher.OnNeverAskAgain;
import permissions.dispatcher.OnPermissionDenied;
import permissions.dispatcher.RuntimePermissions;

@RuntimePermissions
public class MainActivity extends Activity implements OnLinkListener {

    private static final String TAG = "MainActivity";
    private static final String KEY_BLELINKER_BLE_NAME = "BleLinker_ble_name";
    private static final String KEY_BLELINKER_SSID_FORMAT = "BleLinker_ssid.%s";
    private static final String KEY_BLELINKER_USER_DATA = "BleLinker_user_data";
    private static final String KEY_BLELINKER_DEVICE_FINDING_TYPE = "BleLinker_device_finding_type";

    private EditText mSsidEditText;
    private EditText mPasswordEditText;
    private EditText mBleNameEditText;
    private EditText mUserDataEditText;
    private Spinner mDeviceFindingTypeSpinner;
    private Button mLinkButton;
    private TextView mMessageTextView;

    private BleLinker mBleLinker;
    private String mWifiSsid;
    private boolean mWifiConnected;
    private boolean mBluetoothEnabled;
    private ProgressDialog mProgressDialog;
    private ProgressDialog mCancelingDialog;
    private AlertDialog mAlertDialog;
    private SharedPreferences mSharedPreferences;

    private SimpleDateFormat mSimpleDataFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        mSharedPreferences = getSharedPreferences(TAG, MODE_PRIVATE);
        mBleLinker = BleLinker.getInstance(this);

        if (!checkBleProvider()) {
            return;
        }

        setContentView(R.layout.activity_main);
        setupViews();
        mBleLinker.init();
        mBleLinker.setOnLinkListener(this);
    }

    @Override
    protected void onStart() {
        super.onStart();

//        checkLocationProvider();
        MainActivityPermissionsDispatcher.requestPermissionsWithPermissionCheck(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mBleLinker.destroy();
    }

    private void setupViews() {

        mSsidEditText = (EditText) findViewById(R.id.ssid);
        mPasswordEditText = (EditText) findViewById(R.id.password);
        mBleNameEditText = (EditText) findViewById(R.id.ble_name);
        mUserDataEditText = (EditText) findViewById(R.id.user_data);
        mDeviceFindingTypeSpinner = (Spinner) findViewById(R.id.device_finding_type);
        mDeviceFindingTypeSpinner.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, new String[]{"UDP", "BLE", "UDP + BLE"}));
        mMessageTextView = (TextView) findViewById(R.id.message);
        mLinkButton = (Button) findViewById(R.id.link);

        setWidgetsWithSharedPreferences();

        TextWatcher textWatcher = new TextWatcher() {

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {

                if (!mBleLinker.isLinking() && mWifiConnected && mBluetoothEnabled &&
                        !mSsidEditText.getText().toString().isEmpty() && !mBleNameEditText.getText().toString().isEmpty()) {
                    mLinkButton.setEnabled(true);
                } else {
                    mLinkButton.setEnabled(false);
                }
            }
        };

        mSsidEditText.addTextChangedListener(textWatcher);
        mPasswordEditText.addTextChangedListener(textWatcher);
        mBleNameEditText.addTextChangedListener(textWatcher);
        mLinkButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                String ssid = mSsidEditText.getText().toString();
                String password = mPasswordEditText.getText().toString();
                String bleName = mBleNameEditText.getText().toString();
                String userData = mUserDataEditText.getText().toString();
                int deviceFoundOption = mDeviceFindingTypeSpinner.getSelectedItemPosition();

                SharedPreferences.Editor editor = mSharedPreferences.edit();
                editor.putString(String.format(KEY_BLELINKER_SSID_FORMAT, ssid), password);
                editor.putString(KEY_BLELINKER_BLE_NAME, bleName);
                editor.putString(KEY_BLELINKER_USER_DATA, userData);
                editor.putInt(KEY_BLELINKER_DEVICE_FINDING_TYPE, deviceFoundOption);
                editor.commit();

                mBleLinker.setSsid(ssid);
                mBleLinker.setPassword(password);
                mBleLinker.setBleName(bleName);
                mBleLinker.setUserData(userData);
                mBleLinker.setDeviceFindingType(deviceFoundOption + 1);
                try {
                    mBleLinker.start();
                    mLinkButton.setEnabled(false);

                    clearMessage();
                    String text = String.format("Start Ble Link\n  ssid: \"%s\"\n  password: \"%s\"\n  bleName: \"%s\"", ssid, password, bleName);
                    updateMessage(text);
                } catch (Exception e) {
                    e.printStackTrace();
                    showAlertDialog("Start Failed!");
                }
            }
        });

        mCancelingDialog = new ProgressDialog(this);
        mCancelingDialog.setMessage(getString(R.string.blelinker_canceling));
        mCancelingDialog.setCanceledOnTouchOutside(false);
        mCancelingDialog.setCancelable(false);

        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(getPackageName(), PackageManager.GET_ACTIVITIES);
            if (packageInfo != null) {
                ((TextView) findViewById(R.id.version)).setText("version: " + packageInfo.versionName);
            }
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    @NeedsPermission({"android.permission.ACCESS_WIFI_STATE", "android.permission.ACCESS_NETWORK_STATE", "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_FINE_LOCATION", "android.permission.INTERNET", "android.permission.WAKE_LOCK",
            "android.permission.BLUETOOTH", "android.permission.BLUETOOTH_ADMIN", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"})
    public void requestPermissions() {
        HFLog.d(TAG, "requestPermissions: ");
    }

    @OnPermissionDenied({"android.permission.ACCESS_WIFI_STATE", "android.permission.ACCESS_NETWORK_STATE", "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_FINE_LOCATION", "android.permission.INTERNET", "android.permission.WAKE_LOCK",
            "android.permission.BLUETOOTH", "android.permission.BLUETOOTH_ADMIN", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"})
    public void showPermissionDenied() {
        showAlertDialog(getString(R.string.blelinker_permission_denied));
    }


    @OnNeverAskAgain({"android.permission.ACCESS_WIFI_STATE", "android.permission.ACCESS_NETWORK_STATE", "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_FINE_LOCATION", "android.permission.INTERNET", "android.permission.WAKE_LOCK",
            "android.permission.BLUETOOTH", "android.permission.BLUETOOTH_ADMIN", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"})
    public void onPermissionNeverAskAgain() {
        showAlertDialog(getString(R.string.blelinker_permission_denied));
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        MainActivityPermissionsDispatcher.onRequestPermissionsResult(this, requestCode, grantResults);
        mBleLinker.refreshWifiConnectivity(this);
    }

    private void setWidgetsWithSharedPreferences() {
        mPasswordEditText.setText(mSharedPreferences.getString(String.format(KEY_BLELINKER_SSID_FORMAT, mSsidEditText.getText().toString()), null));
        mBleNameEditText.setText(mSharedPreferences.getString(KEY_BLELINKER_BLE_NAME, BleLinker.BLE_NAME_HIFLYING));
        mUserDataEditText.setText(mSharedPreferences.getString(KEY_BLELINKER_USER_DATA, null));
        mDeviceFindingTypeSpinner.setSelection(mSharedPreferences.getInt(KEY_BLELINKER_DEVICE_FINDING_TYPE, 2));
    }

    @Override
    public void onWifiConnectivityChanged(boolean connected, String ssid, WifiInfo wifiInfo) {
        HFLog.d(TAG, String.format("onWifiConnectivityChanged: connected-%s ssid-%s", connected, ssid));

        mWifiConnected = connected;
        mWifiSsid = ssid;
        enableLinkUI(mWifiConnected && mBluetoothEnabled);
    }

    @Override
    public void onBluetoothEnabledChanged(boolean enabled) {
        HFLog.d(TAG, "onBluetoothEnabledChanged: " + enabled);

        mBluetoothEnabled = enabled;
        enableLinkUI(mWifiConnected && mBluetoothEnabled);
    }

    @Override
    public void onModuleLinked(LinkedModule module) {
        HFLog.i(TAG, "onModuleLinked: " + module);

        updateMessage("onModuleLinked: " + module.getMac());
        showAlertDialog("linked module: " + JSON.toJSONString(module));
    }

    @Override
    public void onFinished() {
        HFLog.i(TAG, "onFinished");

        updateMessage("onFinished");
        dismissProgressDialog();
        if (mCancelingDialog.isShowing()) {
            mCancelingDialog.dismiss();
        }
        mLinkButton.setEnabled(true);
    }

    @Override
    public void onModuleLinkTimeOut() {
        HFLog.i(TAG, "onModuleLinkTimeOut");

        updateMessage("onModuleLinkTimeOut");
        showAlertDialog("TIME OUT");
    }

    @Override
    public void onError(LinkingError error) {
        HFLog.i(TAG, "onError: " + error);

        updateMessage("onError: " + error);
        dismissProgressDialog();
        showAlertDialog(error.name());
    }

    @Override
    public void onProgress(LinkingProgress progress) {
        HFLog.i(TAG, "onProgress: " + progress);

        updateMessage("onProgress: " + progress);
        showProgressDialog(progress.name());
    }

    private void enableLinkUI(boolean enabled) {

        if (enabled) {

            mSsidEditText.setText(mWifiSsid);
            mPasswordEditText.setText(mSharedPreferences.getString(String.format(KEY_BLELINKER_SSID_FORMAT, mWifiSsid), null));
            mBleNameEditText.setText(mSharedPreferences.getString(KEY_BLELINKER_BLE_NAME, BleLinker.BLE_NAME_HIFLYING));
            mUserDataEditText.setText(mSharedPreferences.getString(KEY_BLELINKER_USER_DATA, null));

            mPasswordEditText.setEnabled(true);
            mBleNameEditText.setEnabled(true);
            mUserDataEditText.setEnabled(true);
            mDeviceFindingTypeSpinner.setEnabled(true);
            if (mSsidEditText.getText().toString().isEmpty() || mBleNameEditText.getText().toString().trim().isEmpty()) {
                mLinkButton.setEnabled(false);
            } else {
                mLinkButton.setEnabled(true);
            }

//            if (mMessageTextView.getText().toString().equals(getString(R.string.blelinker_no_valid_wifi_connection))) {
//            if (!mBleLinker.isLinking()) {
//                clearMessage();
//            }
        } else {

            mSsidEditText.setText(null);
            mPasswordEditText.setText(null);
            mBleNameEditText.setText(null);
            mUserDataEditText.setText(null);
            mPasswordEditText.setEnabled(false);
            mBleNameEditText.setEnabled(false);
            mUserDataEditText.setEnabled(false);
            mDeviceFindingTypeSpinner.setEnabled(false);
            mLinkButton.setEnabled(false);

//            if (!mBleLinker.isLinking()) {
//
//                clearMessage();
//
//                if (!mWifiConnected) {
//                    updateMessage(getString(R.string.blelinker_no_valid_wifi_connection));
//                }
//
//                if (!mBluetoothEnabled) {
//                    updateMessage(getString(R.string.blelinker_bluetooth_disabled));
//                }
//            }
        }

        if (!mBleLinker.isLinking()) {

            clearMessage();

            if (!enabled) {

                if (!mWifiConnected) {
                    updateMessage(getString(R.string.blelinker_no_valid_wifi_connection));
                }

                if (!mBluetoothEnabled) {
                    updateMessage(getString(R.string.blelinker_bluetooth_disabled));
                }
            }
        }
    }

    private void showProgressDialog(String message) {

        if (mProgressDialog == null) {
            mProgressDialog = new ProgressDialog(this);
            mProgressDialog.setTitle(R.string.blelinker_app_name);
            mProgressDialog.setCanceledOnTouchOutside(false);
            mProgressDialog.setCancelable(false);
            mProgressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, getString(android.R.string.cancel), new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    mBleLinker.stop();
                    mCancelingDialog.show();
                }
            });
//            mProgressDialog.setOnDismissListener(new DialogInterface.OnDismissListener() {
//                @Override
//                public void onDismiss(DialogInterface dialog) {
//                    mBleLinker.stop();
//                }
//            });
        }
        mProgressDialog.setMessage(message);
        if (!mProgressDialog.isShowing()) {
            mProgressDialog.show();
        }
    }

    private void showAlertDialog(String message) {

        if (mAlertDialog == null) {
            mAlertDialog = new AlertDialog.Builder(this)
                    .setTitle(R.string.blelinker_app_name)
                    .setPositiveButton(android.R.string.ok, null)
                    .create();
        }
        mAlertDialog.setMessage(message);
        if (!mAlertDialog.isShowing()) {
            mAlertDialog.show();
        }
    }

    private void dismissProgressDialog() {
        if (mProgressDialog.isShowing()) {
            mProgressDialog.dismiss();
        }
    }

    private void clearMessage() {

        mMessageTextView.setText(null);
    }

    private void updateMessage(String message) {

        message = String.format("[%s] %s", mSimpleDataFormat.format(new Date()), message);
        mMessageTextView.setText(mMessageTextView.getText().toString().concat("\n").concat(message));
    }

    private boolean checkBleProvider() {

        if (mBleLinker.isBleSupported()) {
            return true;
        } else {
            showSimpleDialog(R.string.blelinker_ble_not_supported, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {

                    finish();
                }
            });
            return false;
        }
    }

    private void checkLocationProvider() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

            LocationManager locManager = (LocationManager) getSystemService(LOCATION_SERVICE);
            if (!locManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {

                HFLog.w(TAG, String.format("The android version sdk is %s and its location provider is disabled!", Build.VERSION.SDK_INT));

                new AlertDialog.Builder(this)
                        .setTitle(R.string.blelinker_app_name)
                        .setMessage(R.string.blelinker_location_prodiver_disabled)
                        .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {

                                Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
                                startActivity(intent);
                            }
                        })
                        .create()
                        .show();
            }
        }
    }

    private void showSimpleDialog(int messageResId, DialogInterface.OnClickListener onClickListener) {

        new AlertDialog.Builder(this)
                .setTitle(R.string.blelinker_app_name)
                .setMessage(messageResId)
                .setPositiveButton(android.R.string.ok, onClickListener)
                .setCancelable(false)
                .create()
                .show();
    }

    private void showSimpleDialog(int messageResId) {
        showSimpleDialog(messageResId, null);
    }
}

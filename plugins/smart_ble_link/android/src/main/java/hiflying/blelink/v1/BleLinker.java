package hiflying.blelink.v1;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.AsyncTask;
import android.text.TextUtils;

import hiflying.blelink.GTransformer;
import hiflying.blelink.HFLog;
import hiflying.blelink.LinkerUtils;
import hiflying.blelink.LinkedModule;
import hiflying.blelink.LinkingEncryptor;
import hiflying.blelink.LinkingError;
import hiflying.blelink.LinkingException;
import hiflying.blelink.LinkingProgress;
import hiflying.blelink.LinkingRequestFrameCreator;
import hiflying.blelink.OnLinkListener;
import hiflying.blelink.TeaEncryptor;
import hiflying.blelink.ble.Ble;
import hiflying.blelink.ble.BleCallback;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class BleLinker {

    private static final String TAG = BleLinker.class.getSimpleName();

    public static final String BLE_NAME_HIFLYING = "AZ";
    public static final int DEVICE_FOUNDING_TYPE_UDP = 0x01;
    public static final int DEVICE_FOUNDING_TYPE_BLE = 0x02;
    public static final int DEVICE_FOUNDING_TYPE_UDP_BLE = 0x03;

    private static final String BLE_SERVICE_UUID = "0000fee7-0000-1000-8000-00805f9b34fb";
    private static final String BLE_NOTIFY_CHARACTERISTIC_UUID = "0000fec8-0000-1000-8000-00805f9b34fb";
    private static final String BLE_WRITE_CHARACTERISTIC_UUID = "0000fec7-0000-1000-8000-00805f9b34fb";
    private static final String TEA_ENCRYPTION_KEY = "hiflying12345678";
    private static final String BLE_CONFIG_SUCCESS = "config_success";
    private static final String BLE_CONFIG_FAIL = "config_fail";
    private static final String BLE_CONFIG_ACK = "config_ack";

    /**
     * The udp port to receive smartlink config
     */
    private static int PORT_RECEIVE_SMART_CONFIG = 49999;
    /**
     * The udp port to send smartlinkfind broadcast
     */
    private static int PORT_SEND_SMART_LINK_FIND = 48899;
    private static final int DEFAULT_TIMEOUT_PERIOD = 60000;

    private static String SMART_LINK_FIND = "smartlinkfind";
    private static String SMART_CONFIG = "smart_config";
    private static final int RETRY_MAX_TIMES = 6;

    private Context context;
    private String ssid;
    private String password;
    private String userData;
    private String bleName = BLE_NAME_HIFLYING;
    private int deviceFindingType = DEVICE_FOUNDING_TYPE_UDP_BLE;
    private String bleServiceUuid = BLE_SERVICE_UUID;
    private String bleNotifyCharacteristicUuid = BLE_NOTIFY_CHARACTERISTIC_UUID;
    private String bleWriteCharacteristicUuid = BLE_WRITE_CHARACTERISTIC_UUID;
    private String teaEncryptionKey = TEA_ENCRYPTION_KEY;
    private OnLinkListener onLinkListener;
    private BroadcastReceiver wifiChangedReceiver;
    private WifiManager wifiManager;
    private LinkTask linkTask;
    private LinkingProgress linkingProgress;
    private LinkedModule linkedModule;
    private int timeoutPeriod = DEFAULT_TIMEOUT_PERIOD;
    private Timer timer;
    private boolean isTimeout;
    private WifiManager.WifiLock wifiLock;

    private Ble ble;
    private BroadcastReceiver bluetoothStateChangedReceiver;
    private LinkingStatus linkingStatus = new LinkingStatus();
    private boolean bleNameStrictMatching = true;

    /**
     * The socket to receive smart_config response
     */
    private MulticastSocket mSmartConfigSocket;

    /**
     * The flag indicates the smartlink is working
     */
    private boolean isLinking;

    private LinkingEncryptor linkingEncryptor;

    public String getSsid() {
        return ssid;
    }

    public void setSsid(String ssid) {
        this.ssid = ssid;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getBleName() {
        return bleName;
    }

    public void setBleName(String bleName) {
        this.bleName = bleName;
    }

    public String getUserData() {
        return userData;
    }

    public void setUserData(String userData) {
        this.userData = userData;
    }

    public int getDeviceFindingType() {
        return deviceFindingType;
    }

    /**
     * default is {@link #DEVICE_FOUNDING_TYPE_UDP}
     *
     * @param deviceFindingType
     * @see #DEVICE_FOUNDING_TYPE_UDP
     * @see #DEVICE_FOUNDING_TYPE_BLE
     * @see #DEVICE_FOUNDING_TYPE_UDP_BLE
     */
    public void setDeviceFindingType(int deviceFindingType) {
        this.deviceFindingType = deviceFindingType;
    }

    public void setTimeoutPeriod(int timeoutPeriod) {
        this.timeoutPeriod = timeoutPeriod;
    }

    public boolean isLinking() {
        return isLinking;
    }

    public void setOnLinkListener(OnLinkListener onLinkListener) {
        this.onLinkListener = onLinkListener;

        if (onLinkListener != null) {

            try {
                onLinkListener.onBluetoothEnabledChanged(ble.isAdapterOn());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void setBleNameStrictMatching(boolean bleNameStrictMatching) {
        this.bleNameStrictMatching = bleNameStrictMatching;
    }

    private static class BleLinkerInner {
        private static final BleLinker BLE_LINKER = new BleLinker();
    }

    private BleLinker() {

        wifiChangedReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                refreshWifiConnectivity(context);
            }
        };

        bluetoothStateChangedReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {

                int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1);
                if (state == BluetoothAdapter.STATE_ON) {

                    if (onLinkListener != null) {

                        try {
                            onLinkListener.onBluetoothEnabledChanged(true);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                } else if (state == BluetoothAdapter.STATE_OFF) {

                    if (onLinkListener != null) {

                        try {
                            onLinkListener.onBluetoothEnabledChanged(false);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
        };
    }

    public static BleLinker getInstance(Context context) {

        if (context == null) {
            throw new NullPointerException();
        }

        BleLinker apLinker = BleLinkerInner.BLE_LINKER;
        if (apLinker.context == null) {

            apLinker.context = context.getApplicationContext();
            apLinker.wifiManager = (WifiManager) apLinker.context.getSystemService(Context.WIFI_SERVICE);
            apLinker.wifiLock = apLinker.wifiManager.createWifiLock(apLinker.context.getPackageName());
            apLinker.ble = Ble.getInstance(apLinker.context);
        }

        return apLinker;
    }

    public WifiInfo getConnectedWifi() {
        return wifiManager.getConnectionInfo();
    }

    public void refreshWifiConnectivity(Context context) {

        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo != null && onLinkListener != null) {

            if (networkInfo.isConnected()) {

                WifiInfo wifiInfo = wifiManager.getConnectionInfo();
                String ssid = wifiInfo == null ? null : wifiInfo.getSSID();
                if (LinkerUtils.isEmptySsid(ssid)) {
                    ssid = networkInfo.getExtraInfo();
                }
                if (LinkerUtils.isEmptySsid(ssid) && wifiInfo != null) {
                    ssid = LinkerUtils.getSsid(context, wifiInfo.getNetworkId());
                }

                try {
                    onLinkListener.onWifiConnectivityChanged(true, LinkerUtils.getPureSsid(ssid), wifiInfo);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            } else {

                try {
                    onLinkListener.onWifiConnectivityChanged(false, null, null);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public void init() {

        context.registerReceiver(wifiChangedReceiver, new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION));
        context.registerReceiver(bluetoothStateChangedReceiver, new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));

        ble.setCallback(new BleCallback() {

            @Override
            public void onDeviceFind(BluetoothDevice device, int rssi, byte[] scanRecord) {
                super.onDeviceFind(device, rssi, scanRecord);
                HFLog.v(TAG, "BleCallback.onDeviceFind: " + device.toString());

                String deviceName = device.getName();
                if (!TextUtils.isEmpty(deviceName) &&
                        ((bleNameStrictMatching && deviceName.equals(bleName)) ||
                                (!bleNameStrictMatching && deviceName.contains(bleName)))) {

                    synchronized (linkingStatus) {
                        linkingStatus.setData(LinkingStatus.KEY_SCANNED_BLE, device);
                    }
                    ble.stopScanDevice();
                }
            }

            @Override
            public void onConnectionChanged(int status) {
                super.onConnectionChanged(status);
                HFLog.d(TAG, "BleCallback.onConnectionChanged: " + status);

                if (BleCallback.STATE_CONNECTED == status) {
                    HFLog.d(TAG, "ble connection is created and enable notify");

                    synchronized (linkingStatus) {
                        linkingStatus.setData(LinkingStatus.KEY_CONNECT_BLE, true);
                        linkingStatus.notifyAll();
                    }
                }
            }

            @Override
            public void onDataNotified(byte[] data) {
                super.onDataNotified(data);

                String text = new String(data);
                HFLog.d(TAG, String.format("BleCallback.onDataNotified: hex-%s text-'%s'",
                        GTransformer.bytes2HexStringWithWhitespace(data), text));

                if (BLE_CONFIG_SUCCESS.equalsIgnoreCase(text.trim())) {

                    synchronized (linkingStatus) {

                        linkingStatus.setData(LinkingStatus.KEY_CONFIG_BLE_SUCCESS, true);
                        linkingStatus.notifyAll();
                    }
                } else if (BLE_CONFIG_FAIL.equalsIgnoreCase(text.trim())) {

                    synchronized (linkingStatus) {

                        linkingStatus.setData(LinkingStatus.KEY_CONFIG_BLE_SUCCESS, false);
                        linkingStatus.notifyAll();
                    }
                } else {

                    synchronized (linkingStatus) {

                        if (LinkingProgress.FIND_DEVICE.equals(linkingStatus.getProgress())
                                && data.length > 2) {

                            BleDeviceResponseFrames bleDeviceResponseFrames = (BleDeviceResponseFrames) linkingStatus.getData(LinkingStatus.KEY_BLE_FIND_DEVICE);
                            if (bleDeviceResponseFrames != null) {

                                bleDeviceResponseFrames.addFrame(data);
                                if (bleDeviceResponseFrames.isCompleted()) {
                                    linkingStatus.notifyAll();
                                }
                            }
                        }
                    }
                }
            }

            @Override
            public void onDataWritten(byte[] data, boolean success) {
                super.onDataWritten(data, success);
                HFLog.d(TAG, String.format("BleCallback.onDataWritten: data-%s success-%s",
                        GTransformer.bytes2HexStringWithWhitespace(data), success));

                if (success) {

                    synchronized (linkingStatus) {

                        if (BLE_CONFIG_ACK.equalsIgnoreCase(new String(data).trim())) {
                            linkingStatus.setData(LinkingStatus.KEY_CONFIG_BLE_ACK, true);
                            linkingStatus.notifyAll();
                        }
                    }
                }
            }

            @Override
            public void onNotifyChanged(Boolean enabled) {
                super.onNotifyChanged(enabled);
                HFLog.d(TAG, "BleCallback.onNotifyChanged: %s" + enabled);

                if (Boolean.TRUE == enabled) {

                    synchronized (linkingStatus) {
                        linkingStatus.setData(LinkingStatus.KEY_ENABLE_BLE_NOTIFY, true);
                        linkingStatus.notifyAll();
                    }
                }
            }

            @Override
            public void onScanFinished() {
                super.onScanFinished();
                HFLog.d(TAG, "BleCallback.onScanFinished");

                synchronized (linkingStatus) {
                    linkingStatus.notifyAll();
                }
            }
        });

        this.resetProperties();
    }

    public void destroy() {

        try {
            context.unregisterReceiver(wifiChangedReceiver);
        } catch (Exception e) {
        }

        try {
            context.unregisterReceiver(bluetoothStateChangedReceiver);
        } catch (Exception e) {
        }

        this.stop();
        if (linkTask != null) {
            linkTask.cancel(true);
        }
        this.resetProperties();
    }

    public void start() throws Exception {

        if (TextUtils.isEmpty(ssid)) {
            throw new Exception("ssid is empty");
        }

        if (TextUtils.isEmpty(bleName)) {
            throw new Exception("bleName is empty");
        }

        if (isLinking) {
            return;
        }

        resetLinkProperties();
        isLinking = true;
        ble.setServiceUuid(bleServiceUuid);
        ble.setNotifyCharacteristicUuid(bleNotifyCharacteristicUuid);
        ble.setReadWriteCharacteristicUuid(bleWriteCharacteristicUuid);
        linkingStatus.reset();
        linkTask = new LinkTask();
        linkTask.execute();
        isTimeout = false;
        timer = new Timer();
        timer.schedule(new TimerTask() {
            @Override
            public void run() {
                HFLog.d(TAG, "time out!");
                isTimeout = true;
                stop();
            }
        }, timeoutPeriod);
    }

    public void stop() {
        isLinking = false;
//never invoke linkTask.cancel to stop task, otherwise it will make the onFinished not be invoked
//        if (linkTask != null) {
//            linkTask.cancel(true);
//        }
        if (timer != null) {
            try {
                timer.cancel();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        synchronized (linkingStatus) {
            linkingStatus.notifyAll();
        }

        if (mSmartConfigSocket != null) {

            try {
                mSmartConfigSocket.close();
            } catch (Exception e) {
            }
        }
    }

    public boolean isBluetoothAdapterEnabled() {
        return ble.isAdapterOn();
    }

    public boolean isBleSupported() {
        return Ble.isBleSupported(context);
    }

    public void requestEnableBluetoothAdapter() {
        Ble.requestEnableBluetoothAdapter(context);
    }

    private void resetProperties() {

        ssid = null;
        password = null;
        bleName = null;
        userData = null;
        onLinkListener = null;
        bleNameStrictMatching = true;
        this.resetLinkProperties();
    }

    private void resetLinkProperties() {

        isLinking = false;
        isTimeout = false;
        linkTask = null;
        linkingProgress = null;
        linkedModule = null;
        timer = null;
    }

    private class LinkTask extends AsyncTask<Void, LinkingProgress, LinkingError> {

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            try {
                wifiLock.acquire();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        @Override
        protected void onPostExecute(LinkingError error) {

            HFLog.d(TAG, "onPostExecute: " + error);

            if (timer != null) {
                timer.cancel();
            }

            try {
                wifiLock.release();
            } catch (Exception e) {
                e.printStackTrace();
            }

            if (onLinkListener != null) {

                if (error == null) {

                    if (linkedModule != null) {
                        try {
                            onLinkListener.onModuleLinked(linkedModule);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    } else if (isTimeout) {
                        try {
                            onLinkListener.onModuleLinkTimeOut();
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                } else {

                    try {
                        onLinkListener.onError(error);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                try {
                    onLinkListener.onFinished();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            resetLinkProperties();
        }

        @Override
        protected void onProgressUpdate(LinkingProgress... values) {

            linkingProgress = values[0];
            if (onLinkListener != null) {
                try {
                    onLinkListener.onProgress(linkingProgress);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        protected LinkingError doInBackground(Void... voids) {

            if (!ble.isAdapterOn()) {
                return LinkingError.BLUETOOTH_DISABLED;
            }

            if (getConnectedWifi() == null) {
                return LinkingError.NO_VALID_WIFI_CONNECTION;
            }

            try {

                publishProgress(LinkingProgress.SCAN_BLE);
                BluetoothDevice scannedBleDevice = scanBle();
                if (scannedBleDevice == null) {
                    HFLog.w(TAG, "LinkTask->scanBle: scan failed");
                    return LinkingError.BLE_NOT_FOUND;
                } else {
                    HFLog.i(TAG, "LinkTask->scanBle: scan succeed, address is " + scannedBleDevice.getAddress());
                }

                HFLog.i(TAG, "LinkTask->connectBle: " + scannedBleDevice.getAddress());
                publishProgress(LinkingProgress.CONNECT_BLE);
                long startTime = System.currentTimeMillis();
                if (!connectBle(scannedBleDevice.getAddress())) {
                    HFLog.w(TAG, String.format("LinkTask->connect ble device mac-%s failed", scannedBleDevice.getAddress()));
                    return LinkingError.CONNECT_BLE_FAILED;
                }
                HFLog.i(TAG, String.format("LinkTask->connect ble device mac-%s succeed, cost time-%s",
                        scannedBleDevice.getAddress(), System.currentTimeMillis() - startTime));

                linkingEncryptor = new TeaEncryptor(teaEncryptionKey);

                HFLog.i(TAG, "LinkTask->configBle: " + scannedBleDevice.getAddress());
                publishProgress(LinkingProgress.CONFIG_BLE);
                if (!configBle()) {
                    HFLog.w(TAG, String.format("LinkTask->config ble device mac-%s failed", scannedBleDevice.getAddress()));
                    return LinkingError.CONFIG_BLE_FAILED;
                }
                HFLog.i(TAG, String.format("LinkTask->config ble device mac-%s succeed", scannedBleDevice.getAddress()));

                HFLog.i(TAG, "LinkTask->find device");
                publishProgress(LinkingProgress.FIND_DEVICE);
                linkedModule = startSmartDeviceFinding();
                HFLog.i(TAG, String.format("smartlink find: %s", linkedModule));
                if (linkedModule == null) {
                    return LinkingError.FIND_DEVICE_FAILED;
                }
            } catch (LinkingCanceledException e) {
                HFLog.w(TAG, "Ble link task is canceled");
//                e.printStackTrace();
            } catch (LinkingException e) {
                e.printStackTrace();

                return e.getError();
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                ble.disconnect();
                ble.close();
            }

            return null;
        }
    }

    /**
     * Scan ble device with {@link #bleName} in 60 seconds
     *
     * @return
     * @throws LinkingCanceledException
     */
    private BluetoothDevice scanBle() throws LinkingCanceledException {

        linkingStatus.setProgress(LinkingProgress.SCAN_BLE);

        for (int i = 0; i < RETRY_MAX_TIMES; i++) {

            boolean succeed = ble.scanDevice();
            HFLog.d(TAG, String.format("start scan ble device with name '%s' NO.%s time %s", bleName, i + 1, succeed ? "succeed" : "failed"));

            synchronized (linkingStatus) {

                try {
                    linkingStatus.wait(10000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

                if (!isLinking) {
                    throw new LinkingCanceledException();
                }

                if (linkingStatus.getData(LinkingStatus.KEY_SCANNED_BLE) instanceof BluetoothDevice) {
                    return (BluetoothDevice) linkingStatus.getData(LinkingStatus.KEY_SCANNED_BLE);
                }
            }
        }

        return null;
    }

    /**
     * connect the scanned ap in 60 seconds
     *
     * @param mac
     * @return
     * @throws LinkingCanceledException
     */
    private boolean connectBle(String mac) throws LinkingCanceledException {

        linkingStatus.setProgress(LinkingProgress.CONNECT_BLE);

        boolean connectSuccess = false;
        long startedTime = System.currentTimeMillis();
        int times = 0;
        while (System.currentTimeMillis() - startedTime < 50000) {

//            ble.disconnect();
//            sleep(1000);
            times++;
            HFLog.d(TAG, String.format("start to connect ble device NO.%s time", times));
            boolean succeed = ble.connectDevice(mac);
            HFLog.d(TAG, String.format("connect ble device NO.%s time %s", times, succeed ? "succeed" : "failed"));

            synchronized (linkingStatus) {

                try {
                    linkingStatus.wait(2500);
                } catch (InterruptedException e) {
                }

                if (!isLinking) {
                    throw new LinkingCanceledException();
                }

                if (Boolean.TRUE.equals(linkingStatus.getData(LinkingStatus.KEY_CONNECT_BLE))) {
                    connectSuccess = true;
                    break;
                }
            }
        }

        if (!connectSuccess) {
            return false;
        }

        startedTime = System.currentTimeMillis();
        times = 0;
        while (System.currentTimeMillis() - startedTime < 10000) {

            times++;
            HFLog.d(TAG, String.format("enable ble device notify NO.%s time", times));
            ble.enableNotify(true);

            synchronized (linkingStatus) {

                try {
                    linkingStatus.wait(1000);
                } catch (InterruptedException e) {
                }

                if (!isLinking) {
                    throw new LinkingCanceledException();
                }

                if (Boolean.TRUE.equals(linkingStatus.getData(LinkingStatus.KEY_ENABLE_BLE_NOTIFY))) {
                    return true;
                }
            }
        }

        return false;
    }

    private boolean configBle() throws LinkingException {

        linkingStatus.setProgress(LinkingProgress.CONFIG_BLE);

        List<byte[]> frames = new ArrayList<>();
        try {
            frames.addAll(LinkingRequestFrameCreator.createConfigFrames(linkingEncryptor, ssid, password, userData));
        } catch (Exception e) {
            HFLog.e(TAG, "[configBle] Create config request frame error");
            e.printStackTrace();

            throw new LinkingException(LinkingError.ERROR, "Create config request frame error");
        }

        HFLog.d(TAG, "[configBle] Send blelink data to device");

        boolean success = false;
        long startTime = System.currentTimeMillis();
        for (int i = 0; i < frames.size() && isLinking && System.currentTimeMillis() - startTime < 150000; i++) {

            ble.write(frames.get(i));

            synchronized (linkingStatus) {

                try {
                    linkingStatus.wait(500);
                } catch (InterruptedException e) {
                }

                if (!isLinking) {
                    throw new LinkingCanceledException();
                }


                Boolean configSuccess = (Boolean) linkingStatus.getData(LinkingStatus.KEY_CONFIG_BLE_SUCCESS);
                HFLog.d(TAG, String.format("LinkingStatus.KEY_CONFIG_BLE_SUCCESS: %s", configSuccess));

                if (Boolean.TRUE.equals(configSuccess)) {
                    success = true;
                    break;
                } else if (Boolean.FALSE.equals(configSuccess)) {
                    success = false;
                    break;
                }
            }

            if (i == frames.size() - 1) {
                i = -1;
            }
        }

        HFLog.i(TAG, "[configBle] Send blelink data to device %s", success ? "success" : "fail");

        if (!success) {
            return false;
        }

        HFLog.d(TAG, "send config_ack data to device");
        success = false;
        int successCount = 0;
        for (int i = 0; i < RETRY_MAX_TIMES * 2 && isLinking; i++) {

            ble.write(BLE_CONFIG_ACK.getBytes());

            synchronized (linkingStatus) {

                try {
                    linkingStatus.wait(500);
                } catch (InterruptedException e) {
                }

                if (!isLinking) {
                    throw new LinkingCanceledException();
                }

                if (Boolean.TRUE.equals(linkingStatus.getData(LinkingStatus.KEY_CONFIG_BLE_ACK))) {

                    successCount++;
                    if (successCount > 1) {

                        success = true;
                        break;
                    }
                }
            }
        }

        if (!isLinking) {
            throw new LinkingCanceledException("Ble link task is canceled when config");
        }

        HFLog.i(TAG, "[configBle] Send config ack to device %s", success ? "success" : "fail");
        return success;
    }

    private LinkedModule startSmartDeviceFinding() throws LinkingException {

        List<Callable<LinkedModule>> findDeviceCallables = new ArrayList<>();
        if ((deviceFindingType & DEVICE_FOUNDING_TYPE_UDP) == DEVICE_FOUNDING_TYPE_UDP) {
            findDeviceCallables.add(new SmartUdpDeviceFinding());
        }
        if ((deviceFindingType & DEVICE_FOUNDING_TYPE_BLE) == DEVICE_FOUNDING_TYPE_BLE) {
            findDeviceCallables.add(new SmartBleDeviceFinding());
        }
        if (findDeviceCallables.isEmpty()) {
            throw new LinkingException(LinkingError.ERROR, "invalid deviceFindingType");
        }

        List<Future<LinkedModule>> linkedModuleFeatures = new ArrayList<>();
        ExecutorService executorService = Executors.newFixedThreadPool(findDeviceCallables.size());
        ExecutorCompletionService<LinkedModule> completionService = new ExecutorCompletionService<>(executorService);
        for (Callable<LinkedModule> findDeviceCallable : findDeviceCallables) {
            linkedModuleFeatures.add(completionService.submit(findDeviceCallable));
        }

        LinkedModule linkedModule = null;
        try {
            linkedModule = completionService.take().get();
        } catch (ExecutionException e) {
            e.printStackTrace();

            if (e.getCause() instanceof LinkingException) {
                throw (LinkingException) e.getCause();
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {

            for (Future<LinkedModule> linkedModuleFuture : linkedModuleFeatures) {
                linkedModuleFuture.cancel(true);
            }
        }

        if (!isLinking) {
            throw new LinkingCanceledException("Ble link task is canceled when find device");
        }

        if (linkedModule == null) {
            throw new LinkingException(LinkingError.FIND_DEVICE_FAILED);
        } else {
            return linkedModule;
        }
    }

    private class SmartBleDeviceFinding implements Callable<LinkedModule> {

        @Override
        public LinkedModule call() throws Exception {

            HFLog.i(TAG, "[SmartBleDeviceFinding] Start finding");

            synchronized (linkingStatus) {
                linkingStatus.setProgress(LinkingProgress.FIND_DEVICE);
                linkingStatus.setData(LinkingStatus.KEY_BLE_FIND_DEVICE, new BleDeviceResponseFrames());
            }

            while (isLinking && !Thread.currentThread().isInterrupted()) {

                synchronized (linkingStatus) {

                    try {
                        linkingStatus.wait(1000);
                    } catch (InterruptedException e) {
                    }

                    BleDeviceResponseFrames bleDeviceResponseFrames = (BleDeviceResponseFrames) linkingStatus.getData(LinkingStatus.KEY_BLE_FIND_DEVICE);
                    if (bleDeviceResponseFrames.isCompleted()) {

                        byte[] deviceResponseData = bleDeviceResponseFrames.unpackAndDecryptFrames(linkingEncryptor);
                        String jsonText = null;
                        try {
                            jsonText = new String(deviceResponseData, "UTF-8");
                            HFLog.i(TAG, "[SmartBleDeviceFinding] Ble device find text: %s", jsonText);

                            JSONObject jsonObject = new JSONObject(jsonText);
                            String error = jsonObject.optString("err", "").trim();
                            String ip = jsonObject.optString("ip", "").trim();

                            if (error.isEmpty() && !ip.isEmpty()) {

                                String mac = jsonObject.optString("mac", "").trim();
                                String mid = jsonObject.optString("mid", "").trim();
                                LinkedModule linkedModule = new LinkedModule(mac, ip, mid);
                                HFLog.i(TAG, "[SmartBleDeviceFinding] Device found: %s", linkedModule);

                                return linkedModule;
                            } else if ("apNotExist".equalsIgnoreCase(error)) {
                                throw new LinkingException(LinkingError.FIND_DEVICE_FAILED_AP_NOT_EXIST);
                            } else if ("password".equalsIgnoreCase(error)) {
                                throw new LinkingException(LinkingError.FIND_DEVICE_FAILED_AP_PASSWORD_ERROR);
                            } else {
                                throw new LinkingException(LinkingError.FIND_DEVICE_FAILED);
                            }
                        } catch (UnsupportedEncodingException e) {
                            HFLog.e(TAG, "[SmartBleDeviceFinding] Stringify wholeBleDeviceFindingPlainFrame error: UTF-8 not support");
                            e.printStackTrace();

                            throw new LinkingException(LinkingError.ERROR, "Stringify device finding response data error, UTF-8 not support");
                        } catch (JSONException e) {
                            HFLog.e(TAG, "[SmartBleDeviceFinding] Make text to JSONObject error");
                            e.printStackTrace();

                            throw new LinkingException(LinkingError.ERROR, "Make text to JSONObject error: " + jsonText);
                        }
                    }
                }
            }
            if (!isLinking) {
                throw new LinkingCanceledException("Ble link task is canceled when smart ble device finding");
            }

            throw new LinkingException(LinkingError.FIND_DEVICE_FAILED, "Smart ble device finding timeout");
        }
    }

    private class SmartUdpDeviceFinding implements Callable<LinkedModule> {

        @Override
        public LinkedModule call() throws Exception {

            HFLog.i(TAG, "[SmartUdpDeviceFinding] Start finding");

            linkingStatus.setProgress(LinkingProgress.FIND_DEVICE);

            try {

                mSmartConfigSocket = LinkerUtils.createMulticastSocket(context, PORT_RECEIVE_SMART_CONFIG);

                byte[] buffer = new byte[1024];
                DatagramPacket pack = new DatagramPacket(buffer, buffer.length);

                while (isLinking && !Thread.currentThread().isInterrupted()) {

                    try {

                        //send smart link find
                        byte[] data = SMART_LINK_FIND.getBytes();
                        try {
                            mSmartConfigSocket.send(new DatagramPacket(data, data.length,
                                    InetAddress.getByName(LinkerUtils.getBroadcastAddress(context)), PORT_SEND_SMART_LINK_FIND));
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                        synchronized (linkingStatus) {
                            try {
                                linkingStatus.wait(100);
                            } catch (InterruptedException e) {
                            }
                        }

                        mSmartConfigSocket.receive(pack);
                        byte[] bytes = new byte[pack.getLength()];
                        System.arraycopy(buffer, 0, bytes, 0, bytes.length);

                        if (bytes.length >= 25) {

                            boolean ignore = true;
                            for (int i = 0; i < bytes.length; i++) {
                                ignore = bytes[i] == 5;
                                if (!ignore) {
                                    break;
                                }
                            }

                            if (!ignore) {
                                StringBuffer sb = new StringBuffer();
                                for (int i = 0; i < bytes.length; i++) {
                                    sb.append((char) bytes[i]);
                                }

                                String result = sb.toString().trim();
                                String mac = null, ip = null, id = null;

                                HFLog.d(TAG, "[SmartUdpDeviceFinding] Received: " + result);

                                if (result.startsWith(SMART_CONFIG)) {

                                    result = result.replace(SMART_CONFIG, "").trim();
                                    String[] items = result.split("##");

                                    if (items.length > 0) {

                                        mac = items[0].trim();
                                        id = items.length > 1 && !TextUtils.isEmpty(items[1].trim()) ? items[1].trim() : mac;
                                    }
                                } else {

                                    try {
                                        JSONObject jsonObject = new JSONObject(result);
                                        id = jsonObject.optString("mid");
                                        mac = jsonObject.optString("mac");
                                        ip = jsonObject.optString("ip");
                                    } catch (JSONException e) {
                                        // TODO Auto-generated catch block
                                        e.printStackTrace();
                                    }
                                }

//                            if (!TextUtils.isEmpty(mac) && isSmartLinkFoundMatched(mac)) {
                                if (!TextUtils.isEmpty(mac)) {

                                    if (TextUtils.isEmpty(id) || id.trim().isEmpty()) {
                                        id = mac;
                                    }

                                    if (TextUtils.isEmpty(ip)) {
                                        ip = pack.getAddress().getHostAddress();
                                    }


                                    LinkedModule linkedModule = new LinkedModule(mac, ip, id);
                                    HFLog.i(TAG, "[SmartUdpDeviceFinding] Device found: %s", linkedModule);

                                    return linkedModule;
                                }
                            }
                        }
                    } catch (IOException e) {
                        HFLog.v(TAG, "[SmartUdpDeviceFinding] SmartLinkSocket.receive(pack) timeout");
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {

                if (mSmartConfigSocket != null) {

                    try {
                        mSmartConfigSocket.disconnect();
                        mSmartConfigSocket.close();
                        mSmartConfigSocket = null;
                    } catch (Exception e) {
                    }
                }
            }

            if (!isLinking) {
                throw new LinkingCanceledException("Ble link task is canceled when smart udp device finding");
            }

            throw new LinkingException(LinkingError.FIND_DEVICE_FAILED, "Smart udp device finding timeout");
        }
    }

    private void sleep(long time) {
        try {
            Thread.sleep(time);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

package hiflying.blelink.ble;

import java.util.Arrays;
import java.util.HashSet;
import java.util.UUID;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.text.TextUtils;

import hiflying.blelink.GTransformer;
import hiflying.blelink.HFLog;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
public class Ble {

    private static final String TAG = "Ble";

    private static final int BLE_DISCOVERY_PERIOD = 10 * 1000;
    //	private static final String BT_BOX_SERVICE = "0000fff0-0000-1000-8000-00805f9b34fb";
//	private static final String TRANSFOR_NOTIFY = "0000fff4-0000-1000-8000-00805f9b34fb";
//	private static final String TRANSFOR_READ_WRITE = "0000fff3-0000-1000-8000-00805f9b34fb";
    private static final String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";

    private Context mContext;
    private BluetoothAdapter mAdapter;
    private LeScanCallback mLeScanCallback;
    private BluetoothGatt mBluetoothGatt;
    private BluetoothGattCallback mBluetoothGattCallback;
    private BluetoothGattCharacteristic mNotifyGattCharacteristic;
    private BluetoothGattCharacteristic mReadWriteGattCharacteristic;
    private BleCallback mTransferCallback;
    private Handler mHandler = new Handler();
    private Runnable mCancelScanRunnable;
    private String mMac;
    private boolean mStartScan;
    private HashSet<String> mScanDevices = new HashSet<String>();

    private String serviceUuid;
    private String readWriteCharacteristicUuid;
    private String notifyCharacteristicUuid;

    /**
     * @param mTransferCallback the mTransferCallback to set
     */
    public void setCallback(BleCallback mTransferCallback) {
        this.mTransferCallback = mTransferCallback;
    }

    /**
     * @return the serviceUuid
     */
    public String getServiceUuid() {
        return serviceUuid;
    }

    /**
     * @param serviceUuid the serviceUuid to set
     */
    public void setServiceUuid(String serviceUuid) {
        this.serviceUuid = serviceUuid;
    }

    /**
     * @return the readWriteCharacteristicUuid
     */
    public String getReadWriteCharacteristicUuid() {
        return readWriteCharacteristicUuid;
    }

    /**
     * @param readWriteCharacteristicUuid the readWriteCharacteristicUuid to set
     */
    public void setReadWriteCharacteristicUuid(String readWriteCharacteristicUuid) {
        this.readWriteCharacteristicUuid = readWriteCharacteristicUuid;
    }

    /**
     * @return the notifyCharacteristicUuid
     */
    public String getNotifyCharacteristicUuid() {
        return notifyCharacteristicUuid;
    }

    /**
     * @param notifyCharacteristicUuid the notifyCharacteristicUuid to set
     */
    public void setNotifyCharacteristicUuid(String notifyCharacteristicUuid) {
        this.notifyCharacteristicUuid = notifyCharacteristicUuid;
    }

    public static Ble getInstance(Context context) {

        if (BleTransferInner.instance.mContext == null) {
            BleTransferInner.instance.init(context);
        }
        return BleTransferInner.instance;
    }

    private static class BleTransferInner {
        private static final Ble instance = new Ble();
    }

    private Ble init(Context context) {
        this.mContext = context;
        BluetoothManager manager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        mAdapter = manager.getAdapter();
        mLeScanCallback = new LeScanCallback() {

            @Override
            public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
                // TODO Auto-generated method stub

                HFLog.v(TAG, "onLeScan: " + device);

                if (TextUtils.isEmpty(mMac)) {

                    if (!mScanDevices.contains(device.getAddress())) {

                        mScanDevices.add(device.getAddress());
                        if (mTransferCallback != null) {
                            mTransferCallback.onDeviceFind(device, rssi, scanRecord);
                        }
                    }
                } else {

                    if (device.getAddress().equals(mMac)) {
                        stopScanDevice();
                        if (mTransferCallback != null) {
                            mTransferCallback.onDeviceFind(true);
                        }
                    }
                }
            }
        };
        mBluetoothGattCallback = new BluetoothGattCallback() {

            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status,
                                                int newState) {
                // TODO Auto-generated method stub
                super.onConnectionStateChange(gatt, status, newState);
                HFLog.i(TAG, String.format("onConnectionStateChange: status-%s newState-%s", status, newState));

                Integer state = null;

                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    HFLog.i(TAG, "onConnectionStateChange: STATE_CONNECTED, discover services...");

                    if (mBluetoothGatt != null) {
                        mBluetoothGatt.discoverServices();
                    }
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    state = BleCallback.STATE_DISCONNECTED;
                }

                if (state != null && mTransferCallback != null) {
                    mTransferCallback.onConnectionChanged(state);
                }
            }

            @Override
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                // TODO Auto-generated method stub
                super.onServicesDiscovered(gatt, status);
                HFLog.v(TAG, "onServicesDiscovered: status-" + status);

                int state = -1;
                if (status == BluetoothGatt.GATT_SUCCESS) {

                    for (BluetoothGattService service : gatt.getServices()) {

                        HFLog.d(TAG, "onServicesDiscovered:" + service.getUuid());

                        if (service.getUuid().equals(UUID.fromString(serviceUuid))) {

                            if (!TextUtils.isEmpty(notifyCharacteristicUuid)) {

                                mNotifyGattCharacteristic = service.getCharacteristic(
                                        UUID.fromString(notifyCharacteristicUuid));
                            }

                            if (!TextUtils.isEmpty(readWriteCharacteristicUuid)) {

                                mReadWriteGattCharacteristic = service.getCharacteristic(
                                        UUID.fromString(readWriteCharacteristicUuid));
                            }
							
						/*	if (mNotifyGattCharacteristic != null && mReadWriteGattCharacteristic != null) {
								
								state = BleCallback.STATE_CONNECTED;
								BluetoothGattDescriptor descriptor = mNotifyGattCharacteristic.getDescriptor(
										UUID.fromString(CLIENT_CHARACTERISTIC_CONFIG));
								if (descriptor != null && 
										descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) && 
										mBluetoothGatt.writeDescriptor(descriptor) &&
										mBluetoothGatt.setCharacteristicNotification(mNotifyGattCharacteristic, true)) {

									state = BleTransferCallback.STATE_CONNECTED;
								}
								break;
							}*/

                            state = BleCallback.STATE_CONNECTED;
                            break;
                        }
                    }

                    if (state == BleCallback.STATE_CONNECTED && mTransferCallback != null) {
                        mTransferCallback.onConnectionChanged(state);
                    } else {
                        HFLog.w(TAG, "Not find service " + serviceUuid);
                        disconnect();
                    }

                } else {
                    HFLog.w(TAG, "onServicesDiscovered status: " + status);
                    mBluetoothGatt.disconnect();
                }
            }

            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt,
                                                BluetoothGattCharacteristic characteristic) {
                // TODO Auto-generated method stub
                super.onCharacteristicChanged(gatt, characteristic);

                HFLog.i(TAG, "onCharacteristicChanged: address-" + gatt.getDevice().getAddress() +
                        " uuid-" + characteristic.getUuid());
                if (mTransferCallback != null) {
                    mTransferCallback.onDataNotified(characteristic.getValue());
                }
            }

            @Override
            public void onCharacteristicWrite(BluetoothGatt gatt,
                                              BluetoothGattCharacteristic characteristic, int status) {
                // TODO Auto-generated method stub
                super.onCharacteristicWrite(gatt, characteristic, status);
                HFLog.i(TAG, "onCharacteristicWrite: address-" + gatt.getDevice().getAddress() +
                        " uuid-" + characteristic.getUuid() + " status-" + status);
                if (mTransferCallback != null) {
                    mTransferCallback.onDataWritten(characteristic.getValue(), status == BluetoothGatt.GATT_SUCCESS);
                }
            }

            @Override
            public void onCharacteristicRead(BluetoothGatt gatt,
                                             BluetoothGattCharacteristic characteristic, int status) {
                // TODO Auto-generated method stub
                super.onCharacteristicRead(gatt, characteristic, status);

                HFLog.i(TAG, "onCharacteristicRead: address-" + gatt.getDevice().getAddress() +
                        " characteristic-" + Arrays.toString(characteristic.getValue()) + " status-" + status);

                if (status == BluetoothGatt.GATT_SUCCESS && mTransferCallback != null) {
                    mTransferCallback.onDataRead(gatt, characteristic, characteristic.getValue());
                }
            }

            @Override
            public void onDescriptorWrite(BluetoothGatt gatt,
                                          BluetoothGattDescriptor descriptor, int status) {
                // TODO Auto-generated method stub
                super.onDescriptorWrite(gatt, descriptor, status);

                HFLog.i(TAG, "onDescriptorWrite: address-" + gatt.getDevice().getAddress() +
                        " descriptor-" + descriptor.getUuid() + " status-" + status);
                if (descriptor.getUuid().toString().equals(CLIENT_CHARACTERISTIC_CONFIG) && mTransferCallback != null) {

                    if (status == BluetoothGatt.GATT_SUCCESS) {

                        boolean enable = Arrays.equals(descriptor.getValue(), BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                        if (enable) {
                            mTransferCallback.onNotifyChanged(true);
                        } else {
                            enable = Arrays.equals(descriptor.getValue(), BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                            if (enable) {
                                mTransferCallback.onNotifyChanged(false);
                            } else {
                                mTransferCallback.onNotifyChanged(null);
                            }
                        }
                    } else {
                        mTransferCallback.onNotifyChanged(null);
                    }
//					if (status == BluetoothGatt.GATT_SUCCESS) {
//						mTransferCallback.onNotifyChanged(true);
//					}else {
//						mTransferCallback.onNotifyChanged(null);
//					}
                }
            }

            @Override
            public void onDescriptorRead(BluetoothGatt gatt,
                                         BluetoothGattDescriptor descriptor, int status) {
                // TODO Auto-generated method stub
                super.onDescriptorRead(gatt, descriptor, status);

                HFLog.i(TAG, "onDescriptorRead: address-" + gatt.getDevice().getAddress() +
                        " descriptor-" + descriptor.getUuid() + " status-" + status);
                if (descriptor.getUuid().toString().equals(CLIENT_CHARACTERISTIC_CONFIG) && mTransferCallback != null) {

                    if (status == BluetoothGatt.GATT_SUCCESS) {

                        boolean enable = Arrays.equals(descriptor.getValue(), BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                        if (enable) {
                            mTransferCallback.onNotifyRead(true);
                        } else {
                            enable = Arrays.equals(descriptor.getValue(), BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                            if (enable) {
                                mTransferCallback.onNotifyRead(false);
                            } else {
                                mTransferCallback.onNotifyRead(null);
                            }
                        }
                    } else {
                        mTransferCallback.onNotifyRead(null);
                    }
                }
            }
        };
        mCancelScanRunnable = new Runnable() {

            @Override
            public void run() {
                mAdapter.stopLeScan(mLeScanCallback);
                if (mTransferCallback != null) {
                    mTransferCallback.onDeviceFind(false);
                }
                if (mStartScan) {

                    mStartScan = false;
                    if (mTransferCallback != null) {
                        mTransferCallback.onScanFinished();
                    }
                }
            }
        };
        return this;
    }

    private Ble() {
    }

    public boolean hasAdapter() {
        return mAdapter != null;
    }

    public boolean isAdapterOn() {
        return mAdapter.isEnabled();
    }

    /**
     * Get the current state of the local Bluetooth adapter.
     * <p>Possible return values are
     * {@link BluetoothAdapter#STATE_OFF},
     * {@link BluetoothAdapter#STATE_TURNING_ON},
     * {@link BluetoothAdapter#STATE_ON},
     * {@link BluetoothAdapter#STATE_TURNING_OFF}.
     * <p>Requires {@link android.Manifest.permission#BLUETOOTH}
     *
     * @return current state of Bluetooth adapter
     */
    public int getAdapterState() {
        return mAdapter.getState();
    }

    public static boolean hasAdapter(Context context) {
        return getAdapter(context) != null;
    }

    public static boolean isAdapterOn(Context context) {

        BluetoothAdapter adapter = getAdapter(context);
        return adapter != null && adapter.isEnabled();
    }

    /**
     * Starts a scan for a Bluetooth LE device with its MAC address.
     *
     * <p>Results of the scan are reported using the
     * {@link BleCallback#onDeviceFind(BluetoothDevice, int, byte[])} callback.
     *
     * <p>Requires {@link android.Manifest.permission#BLUETOOTH_ADMIN} permission.
     *
     * @param mac the MAC address of Bluetooth LE device to scan
     * @return true, if the scan was started successfully
     */
    public synchronized boolean scanDevice(final String mac) {

        String prettyMac = GTransformer.toMac(mac);
        if (prettyMac == null || mAdapter.getRemoteDevice(prettyMac) == null) {
            throw new IllegalArgumentException("invalid mac address: " + mac);
        }

        if (!mStartScan) {

            mStartScan = true;
            mMac = prettyMac;
//			stopScanDevice();
            mHandler.postDelayed(mCancelScanRunnable, BLE_DISCOVERY_PERIOD);

            boolean success = mAdapter.startLeScan(mLeScanCallback);
            HFLog.i(TAG, "scanDevice:" + prettyMac + " success-" + success);
            return success;
        } else {
            return false;
        }
    }

    /**
     * Starts a scan for Bluetooth LE devices.
     *
     * <p>Results of the scan are reported using the
     * {@link BleCallback#onDeviceFind(BluetoothDevice, int, byte[])} callback.
     *
     * <p>Requires {@link android.Manifest.permission#BLUETOOTH_ADMIN} permission.
     *
     * @return true, if the scan was started successfully
     */
    public synchronized boolean scanDevice() {

        if (!mStartScan) {

            mMac = null;
            mScanDevices.clear();

            HFLog.i(TAG, "scanDevice");
//			stopScanDevice();
            mStartScan = true;
            mHandler.postDelayed(mCancelScanRunnable, BLE_DISCOVERY_PERIOD);
            return mAdapter.startLeScan(mLeScanCallback);
        } else {
            return false;
        }
    }

    /**
     * Stops an ongoing Bluetooth LE device scan.
     *
     * <p>reported using the
     * {@link BleCallback#onScanFinished()} callback when scan stoped.
     *
     * <p>Requires {@link android.Manifest.permission#BLUETOOTH_ADMIN} permission.
     */
    public synchronized void stopScanDevice() {
        HFLog.i(TAG, "stopScanDevice");
        if (mStartScan) {

            mStartScan = false;
            mHandler.removeCallbacks(mCancelScanRunnable);
            mAdapter.stopLeScan(mLeScanCallback);
            if (mTransferCallback != null) {
                mTransferCallback.onScanFinished();
            }
        }
    }

    public synchronized boolean connectDevice(String mac) {

        mMac = mac;
        if (mMac == null) {
            throw new RuntimeException("mac is null");
        }

        BluetoothDevice device = mAdapter.getRemoteDevice(mMac);
        if (device == null) {
            throw new IllegalArgumentException("invalid mac: " + mMac);
        }

        if (mBluetoothGatt == null) {

            HFLog.i(TAG, "create a new BluetoothGatt connection");
            mBluetoothGatt = device.connectGatt(mContext, false, mBluetoothGattCallback);
            if (mBluetoothGatt == null) {
                return false;
            } else {

                if (mTransferCallback != null) {
                    mTransferCallback.onConnectionChanged(BleCallback.STATE_CONNECTING);
                }
                return true;
            }
        } else if (mBluetoothGatt.connect()) {

            HFLog.i(TAG, "a previous mBluetoothGatt connection exist, reconnect it");
            if (mTransferCallback != null) {
                mTransferCallback.onConnectionChanged(BleCallback.STATE_CONNECTING);
            }
            return true;
        } else {
            onConnectDeviceFailed();
            return false;
        }
    }

    public synchronized boolean connectDevice() {
        return connectDevice(mMac);
    }

    public synchronized void disconnect() {

        HFLog.i(TAG, "disconnect");
        if (mBluetoothGatt != null) {
            HFLog.i(TAG, "mBluetoothGatt.disconnect");
            mBluetoothGatt.disconnect();
        }
    }

    public synchronized void close() {

        HFLog.i(TAG, "close");
        if (mBluetoothGatt != null) {
            mBluetoothGatt.disconnect();
            mBluetoothGatt.close();
            mBluetoothGatt = null;
            HFLog.i(TAG, "mBluetoothGatt.close");
        }
    }

    /**
     * Write the data to characteristic with uuid({@link #readWriteCharacteristicUuid}).
     * A {@link BleCallback#onDataWritten(byte[], boolean)}  callback is triggered
     * to report the result of the write operation.
     *
     * @param data
     */
    public void write(final byte[] data) {

        HFLog.i(TAG, "write: " + GTransformer.bytes2HexStringWithWhitespace(data));
        if (mReadWriteGattCharacteristic != null && mBluetoothGatt != null) {
            HFLog.i(TAG, "setValue:" + mReadWriteGattCharacteristic.setValue(data));
            mReadWriteGattCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
            HFLog.i(TAG, "writeCharacteristic:" + mBluetoothGatt.writeCharacteristic(mReadWriteGattCharacteristic));
        }
    }

    /**
     * Write the data on characteristic with uuid({@link #readWriteCharacteristicUuid}).
     * A {@link BleCallback#onDataRead(BluetoothGatt, BluetoothGattCharacteristic, byte[])} callback is triggered
     * to report the result of the read operation.
     */
    public void read() {
        HFLog.i(TAG, "read");
        mBluetoothGatt.readCharacteristic(mReadWriteGattCharacteristic);
    }

    /**
     * Enable the notify. A {@link BleCallback#onNotifyChanged(Boolean)} callback is triggered
     * to report the result of the enable operation.
     *
     * @param enable
     */
    public void enableNotify(boolean enable) {

        if (mBluetoothGatt != null && mNotifyGattCharacteristic != null) {

            mBluetoothGatt.setCharacteristicNotification(mNotifyGattCharacteristic, enable);

            BluetoothGattDescriptor descriptor = mNotifyGattCharacteristic.getDescriptor(
                    UUID.fromString(CLIENT_CHARACTERISTIC_CONFIG));
            if (descriptor != null) {
                descriptor.setValue(enable ? BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE :
                        BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                mBluetoothGatt.writeDescriptor(descriptor);
            }
        }
    }

    /**
     * Read the notify enabled status, A {@link BleCallback#onNotifyRead(Boolean)} callback is triggered
     * to report the result of the read operation.
     */
    public void readNotifyEnabled() {

        HFLog.i(TAG, "readNotifyEnabled:mNotifyGattCharacteristic-" + mNotifyGattCharacteristic);

        if (mBluetoothGatt != null && mNotifyGattCharacteristic != null) {

            BluetoothGattDescriptor descriptor = mNotifyGattCharacteristic.getDescriptor(
                    UUID.fromString(CLIENT_CHARACTERISTIC_CONFIG));
            if (descriptor != null) {
                mBluetoothGatt.readDescriptor(descriptor);
            }
        }
    }

    public BluetoothDevice getBluetoothDevice() {
        if (mAdapter != null) {
            return mAdapter.getRemoteDevice(mMac);
        }
        return null;
    }

    public static boolean isBleSupported(Context context) {
        return context.getPackageManager().hasSystemFeature(
                PackageManager.FEATURE_BLUETOOTH_LE);
    }

    /**
     * @return the mAdapter
     */
    public BluetoothAdapter getAdapter() {
        return mAdapter;
    }

    public static BluetoothManager getBluetoothManager(Context context) {
        return (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
    }

    /**
     * @return the mAdapter
     */
    public static BluetoothAdapter getAdapter(Context context) {
        return getBluetoothManager(context).getAdapter();
    }

    private void onConnectDeviceFailed() {

        if (mTransferCallback != null) {
            mTransferCallback.onConnectionChanged(BleCallback.STATE_DISCONNECTED);
        }
        disconnect();
        close();
    }

    public static void requestEnableBluetoothAdapter(Context context) {
        context.startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
    }

    public static void registerBluetoothStateChangedListener(Context context, OnBluetoothStateChangedListener listener) {
        context.registerReceiver(listener, new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));
    }

    public static void unregisterBluetoothStateChangedListener(Context context, OnBluetoothStateChangedListener listener) {
        try {
            context.unregisterReceiver(listener);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

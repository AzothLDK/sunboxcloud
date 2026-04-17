package hiflying.blelink.v1;

import hiflying.blelink.LinkingProgress;

import java.util.HashMap;
import java.util.Map;

class LinkingStatus {

    private LinkingProgress progress;
    private Map<String, Object> data = new HashMap<>();
    public static final String KEY_SCANNED_BLE = "KEY_SCANNED_BLE";
    public static final String KEY_CONNECT_BLE = "KEY_CONNECT_BLE";
    public static final String KEY_ENABLE_BLE_NOTIFY = "KEY_ENABLE_BLE_NOTIFY";
    public static final String KEY_CONFIG_BLE_SUCCESS = "KEY_CONFIG_BLE_SUCCESS";
    public static final String KEY_CONFIG_BLE_ACK = "KEY_CONFIG_BLE_ACK";
    public static final String KEY_BLE_FIND_DEVICE = "KEY_BLE_FIND_DEVICE";

    public Map<String, Object> getData() {
        return new HashMap<>(data);
    }

    public Object getData(String key) {
        return data.get(key);
    }

    public void setData(String key, Object value) {
        data.put(key, value);
    }

    public LinkingProgress getProgress() {
        return progress;
    }

    public void setProgress(LinkingProgress progress) {
        this.progress = progress;
    }

    public LinkingStatus(LinkingProgress progress) {
        this.progress = progress;
    }

    public LinkingStatus() {
    }

    public void reset() {
        data.clear();
        progress = null;
    }
}

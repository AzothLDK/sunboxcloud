package hiflying.blelink;

public enum LinkingError {
    /**
     * Internal Error
     */
    ERROR,
    /**
     * Cancel the ble link task
     */
    CANCEL,
    /**
     * The bluetooth adapter is disabled
     */
    BLUETOOTH_DISABLED,
    /**
     * The's no valid wifi connection
     */
    NO_VALID_WIFI_CONNECTION,
    /**
     * Ble device not found
     */
    BLE_NOT_FOUND,
    /**
     * Connect ble device found
     */
    CONNECT_BLE_FAILED,
    /**
     * Config ble device found
     */
    CONFIG_BLE_FAILED,
    /**
     * Not find any linked modules
     */
    FIND_DEVICE_FAILED,
    /**
     * Not find any linked modules because ap password error
     */
    FIND_DEVICE_FAILED_AP_PASSWORD_ERROR,
    /**
     * Not find any linked modules because ap not exist
     */
    FIND_DEVICE_FAILED_AP_NOT_EXIST
}

package hiflying.blelink;

import android.content.Context;
import android.net.DhcpInfo;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.text.TextUtils;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.MulticastSocket;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.Enumeration;
import java.util.List;

public class LinkerUtils {

    public static boolean isBlank(String ssid) {
        return TextUtils.isEmpty(ssid) || ssid.trim().isEmpty();
    }

    public static boolean isEmptySsid(String ssid) {

        if (isBlank(ssid)) {
            return true;
        }

        if (getPureSsid(ssid).toLowerCase().contains("<unknown ssid>")) {
            return true;
        }

        return false;
    }

    public static boolean isEmptyBssid(String bssid) {

        if (isBlank(bssid)) {
            return true;
        }

        bssid = bssid.trim();
        if (bssid.equals("000000000000") || bssid.equals("00-00-00-00-00-00") || bssid.equals("00:00:00:00:00:00")) {
            return true;
        }

        return false;
    }

    public static String getSsid(Context context, int networkId) {

        if (networkId != -1) {

            WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            List<WifiConfiguration> wifiConfigurations = wifiManager.getConfiguredNetworks();
            if (wifiConfigurations == null) {
                return null;
            }

            for (WifiConfiguration wifiConfiguration : wifiConfigurations) {
                if (wifiConfiguration.networkId == networkId) {
                    return wifiConfiguration.SSID;
                }
            }
        }

        return null;
    }

    public static String getBssid(Context context, int networkId) {

        if (networkId != -1) {

            WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            List<WifiConfiguration> wifiConfigurations = wifiManager.getConfiguredNetworks();
            if (wifiConfigurations != null) {
                return null;
            }

            for (WifiConfiguration wifiConfiguration : wifiConfigurations) {
                if (wifiConfiguration.networkId == networkId) {
                    return wifiConfiguration.BSSID;
                }
            }
        }

        return null;
    }

    public static String getPureSsid(String ssid) {

        if (isBlank(ssid)) {
            return ssid;
        }

        if (ssid.startsWith("\"")) {
            ssid = ssid.substring(1);
        }
        if (ssid.endsWith("\"")) {
            ssid = ssid.substring(0, ssid.length() - 1);
        }

        return ssid;
    }

    /**
     * Convert a IPv4 address from an integer to an InetAddress.
     *
     * @param hostAddress an int corresponding to the IPv4 address in network byte order
     */
    public static InetAddress intToInetAddress(int hostAddress) {
        byte[] addressBytes = {(byte) (0xff & hostAddress),
                (byte) (0xff & (hostAddress >> 8)),
                (byte) (0xff & (hostAddress >> 16)),
                (byte) (0xff & (hostAddress >> 24))};

        try {
            return InetAddress.getByAddress(addressBytes);
        } catch (UnknownHostException e) {
            throw new AssertionError();
        }
    }

    /**
     * Convert a IPv4 address from an InetAddress to an integer
     *
     * @param inetAddr is an InetAddress corresponding to the IPv4 address
     * @return the IP address as an integer in network byte order
     */
    public static int inetAddressToInt(InetAddress inetAddr)
            throws IllegalArgumentException {
        byte[] addr = inetAddr.getAddress();
        return ((addr[3] & 0xff) << 24) | ((addr[2] & 0xff) << 16) |
                ((addr[1] & 0xff) << 8) | (addr[0] & 0xff);
    }

    public static String calculateIpAddress(int ipAddress) {
        return (ipAddress & 0xff) + "." + (ipAddress >> 8 & 0xff) + "."
                + (ipAddress >> 16 & 0xff) + "." + (ipAddress >> 24 & 0xff);
    }

    public static NetworkInterface getNetworkInterface(String ip) {

        if (TextUtils.isEmpty(ip)) {
            return null;
        }

        try {

            Enumeration<NetworkInterface> enumeration = NetworkInterface.getNetworkInterfaces();
            if (enumeration == null) {
                return null;
            }

            while (enumeration.hasMoreElements()) {

                NetworkInterface networkInterface = enumeration.nextElement();
                Enumeration<InetAddress> inetAddresses = networkInterface.getInetAddresses();
                if (inetAddresses != null) {

                    while (inetAddresses.hasMoreElements()) {

                        if (ip.equalsIgnoreCase(inetAddresses.nextElement().getHostAddress())) {
                            return networkInterface;
                        }
                    }
                }
            }
        } catch (SocketException e) {
            e.printStackTrace();
        }

        return null;
    }

    public static String getPureMac(String mac) {

        if (mac == null) {
            return mac;
        }

        String[] toReplaces = new String[]{":", "-", "_", " "};
        for (String toReplace : toReplaces) {
            mac = mac.replaceAll(toReplace, "");
        }
        return mac.trim();
    }

    /**
     * @param ctx
     * @param port port to use
     * @return
     * @throws IOException
     */
    public static MulticastSocket createMulticastSocket(Context ctx, int port) throws IOException {

        MulticastSocket socket = new MulticastSocket(port);
        socket.setSoTimeout(2000);

        NetworkInterface networkInterface = getNetworkInterface(getLocalIpAddress(ctx));
        if (networkInterface != null) {
            try {
                socket.setNetworkInterface(networkInterface);
            } catch (SocketException e) {
                e.printStackTrace();
            }
        }
        try {
//            socket.joinGroup(InetAddress.getByName("239.0.0.0"));
            if (networkInterface == null) {
                socket.joinGroup(InetAddress.getByName("239.0.0.0"));
            } else {
                socket.joinGroup(new InetSocketAddress(InetAddress.getByName("239.0.0.0"), port), networkInterface);
            }
            socket.setLoopbackMode(false);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return socket;
    }

    public static String getLocalIpAddress(Context ctx) {

        WifiManager wifiManager = (WifiManager) ctx.getSystemService(Context.WIFI_SERVICE);
        WifiInfo wifiInfo = wifiManager.getConnectionInfo();
        int ipAddress = 0;
        if (wifiInfo == null || (ipAddress = wifiInfo.getIpAddress()) == 0) {
            return null;
        }
        return LinkerUtils.calculateIpAddress(ipAddress);
    }

    public static String getBroadcastAddress(Context ctx) {

        WifiManager wifiManager = (WifiManager) ctx.getSystemService(Context.WIFI_SERVICE);
        DhcpInfo myDhcpInfo = wifiManager.getDhcpInfo();
        if (myDhcpInfo == null) {
            return "255.255.255.255";
        }
        int broadcast = (myDhcpInfo.ipAddress & myDhcpInfo.netmask)
                | ~myDhcpInfo.netmask;
        byte[] quads = new byte[4];
        for (int i = 0; i < 4; i++)
            quads[i] = (byte) ((broadcast >> i * 8) & 0xFF);
        try {
            return InetAddress.getByAddress(quads).getHostAddress();
        } catch (Exception e) {
            return "255.255.255.255";
        }
    }
}

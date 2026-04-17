package hiflying.blelink;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

public class LinkingRequestFrameCreator {

    private static final String TAG = LinkingRequestFrameCreator.class.getSimpleName();

    private static final byte[] RETRIEVE_WIFI_MAC_REQUEST_DATA = GTransformer.hexString2bytes("ACCF23FF8888");

    public static List<byte[]> createConfigFrames(LinkingEncryptor linkingEncryptor, String ssid, String password, String userData) throws Exception {

        byte[] ssidBytes = getBytes(ssid);
        byte[] passwordBytes = getBytes(password);
        byte[] userDataBytes = getBytes(userData);
        int length = ssidBytes.length + passwordBytes.length + userDataBytes.length + 4;

        ByteBuffer buffer = ByteBuffer.allocate(length);
        buffer.put((byte) (ssidBytes.length & 0xFF));
        if (ssidBytes.length > 0) {
            buffer.put(ssidBytes);
        }
        buffer.put((byte) (passwordBytes.length & 0xFF));
        if (passwordBytes.length > 0) {
            buffer.put(passwordBytes);
        }
        buffer.put((byte) (userDataBytes.length & 0xFF));
        if (userDataBytes.length > 0) {
            buffer.put(userDataBytes);
        }
        buffer.position(0);

        byte[] toCrc = new byte[buffer.capacity() - 1];
        buffer.get(toCrc);
        byte crc = CRC.crc8Maxim(toCrc);
        buffer.put(crc);

        byte[] data = linkingEncryptor.encrypt(buffer.array());
        List<byte[]> frames = createFrames(data);

        for (int i = 0; i < frames.size(); i++) {
            HFLog.d(TAG, String.format("createConfigFrames: NO.%s->%s", i + 1, GTransformer.bytes2HexStringWithWhitespace(frames.get(i))));
        }

        return frames;
    }

    @NonNull
    private static List<byte[]> createFrames(byte[] data) {

        int dataLength = data.length;
        int frameCount = dataLength / 17;
        if (dataLength % 17 != 0) {
            frameCount++;
        }
        int position = 0;
        List<byte[]> frames = new ArrayList<>();
        for (int i = 0; i < frameCount; i++) {

            int frameDataLength = Math.min(dataLength - position, 17);
            byte[] frame = new byte[frameDataLength + 3];
            frame[0] = (byte) ((i + 1) & 0xFF);
            frame[1] = (byte) (frameCount & 0xFF);
            frame[2] = (byte) (frameDataLength & 0xFF);
            System.arraycopy(data, position, frame, 3, frameDataLength);
            frames.add(frame);

            position += frameDataLength;
        }
        return frames;
    }

    private static byte[] getBytes(String text) {
        return TextUtils.isEmpty(text) ? new byte[0] : text.getBytes();
    }
}

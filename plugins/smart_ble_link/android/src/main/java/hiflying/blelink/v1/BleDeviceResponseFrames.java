package hiflying.blelink.v1;

import hiflying.blelink.GTransformer;
import hiflying.blelink.HFLog;
import hiflying.blelink.LinkingEncryptor;
import hiflying.blelink.LinkingError;
import hiflying.blelink.LinkingException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

class BleDeviceResponseFrames {

    private static final String TAG = BleDeviceResponseFrames.class.getSimpleName();

    private int totalFrameCount;
    private Map<Integer, byte[]> frames = new HashMap<>();

    public void reset() {
        totalFrameCount = 0;
        frames.clear();
    }

    public boolean isCompleted() {
        return !frames.isEmpty() && frames.size() == totalFrameCount;
    }

    public void addFrame(byte[] frame) {

        if (!validateFrame(frame) || isCompleted()) {
            return;
        }

        int index = frame[0] & 0xFF;

        if (totalFrameCount == 0) {

            reset();
            totalFrameCount = frame[1] & 0xFF;
            frames.put(index, frame);
        } else if (!frames.containsKey(index)) {
            frames.put(index, frame);
        }
    }

    private byte[] unpackFrames() {

        if (!isCompleted()) {
            return new byte[0];
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

        for (int i = 1; i <= totalFrameCount; i++) {

            byte[] frame = frames.get(i);
            if (frame == null) {
                return new byte[0];
            }

            outputStream.write(frame, 3, frame.length - 3);
        }

        try {
            byte[] unpacked = outputStream.toByteArray();
            if ((unpacked[0] & 0xFF) == 0xFE && (unpacked[1] & 0xFF) == unpacked.length - 2) {
                return Arrays.copyOfRange(unpacked, 2, unpacked.length);
            }
        } finally {
            try {
                outputStream.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return new byte[0];
    }

    public byte[] unpackAndDecryptFrames(LinkingEncryptor linkingEncryptor) throws LinkingException {

        byte[] unpackedData = unpackFrames();
        HFLog.i(TAG, "[unpackAndDecryptFrames] Unpack all frames and get whole data-%s", GTransformer.bytes2HexStringWithWhitespace(unpackedData));

        if (unpackedData.length == 0) {
            throw new LinkingException(LinkingError.ERROR, "Unpack all frames but got no data.");
        }

        try {
            byte[] decryptedData = linkingEncryptor.decrypt(unpackedData);
            return decryptedData;
        } catch (Exception e) {
            HFLog.e(TAG, "[unpackAndDecryptFrames] Decrypt whole data error: %s", GTransformer.bytes2HexStringWithWhitespace(unpackedData));
            e.printStackTrace();
        }

        throw new LinkingException(LinkingError.ERROR, "Decrypt whole data error");
    }

    private boolean validateFrame(byte[] frame) {

        if (frame == null) {
            return false;
        }

        if (frame.length < 3) {
            return false;
        }

        if (frame[0] > frame[1]) {
            return false;
        }

        if (frame[1] < 1) {
            return false;
        }

        if (frame.length - 3 != (frame[2] & 0xFF)) {
            return false;
        }

        return true;
    }
}

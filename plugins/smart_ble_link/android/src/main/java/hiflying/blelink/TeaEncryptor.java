package hiflying.blelink;

import java.nio.ByteBuffer;
import java.util.Arrays;

public class TeaEncryptor implements LinkingEncryptor {

    private static final String TAG = "TeaEncryptor";
    private String key;

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public TeaEncryptor(String key) {
        this.key = key;
    }

    public TeaEncryptor() {
    }

    @Override
    public byte[] encrypt(byte[] plain) throws Exception {

        if (plain == null) {
            throw new Exception("plain cannot be null");
        }

        if (key == null) {
            throw new Exception("key cannot be null");
        }

        byte[] keyBytes = key.getBytes();
        if (keyBytes.length < 16) {
            throw new Exception("The key must have length larger than 16");
        }

        int[] keyInts = GTransformer.bytes2ints(keyBytes);
        int plainLength = plain.length;
        byte[] plain2Ints = Arrays.copyOf(plain, (plainLength / 8) * 8);
        int[] plainInts = GTransformer.bytes2ints(plain2Ints);

        ByteBuffer resultBuffer = ByteBuffer.allocate(plainLength);

        for (int i = 0; i < plainInts.length; i += 2) {

            int delta = 0x9e3779b9;
            int sum = 0;
            int a = plainInts[i];
            int b = plainInts[i + 1];

            for (int j = 0; j < 8; j++) {

                sum += delta;
                a += ((b << 4) + keyInts[0]) ^ (b + sum) ^ ((b >>> 5) + keyInts[1]);
                b += ((a << 4) + keyInts[2]) ^ (a + sum) ^ ((a >>> 5) + keyInts[3]);
            }

            resultBuffer.putInt(a);
            resultBuffer.putInt(b);
        }

        resultBuffer.put(plain, plain2Ints.length, plainLength - plain2Ints.length);
        byte[] encrypted = resultBuffer.array();

        HFLog.d(TAG, String.format("[encrypt]\nplain: %s\nkey: %s\nencrypted: %s", GTransformer.bytes2HexStringWithWhitespace(plain), key,
                GTransformer.bytes2HexStringWithWhitespace(encrypted)));

        return encrypted;
    }

    @Override
    public byte[] decrypt(byte[] encrypted) throws Exception {

        if (encrypted == null) {
            throw new Exception("encrypted cannot be null");
        }

        if (key == null) {
            throw new Exception("key cannot be null");
        }

        byte[] keyBytes = key.getBytes();
        if (keyBytes.length < 16) {
            throw new Exception("The key must have length larger than 16");
        }

        int[] keyInts = GTransformer.bytes2ints(keyBytes);
        int encryptedLength = encrypted.length;
        byte[] encrypted2Ints = Arrays.copyOf(encrypted, (encryptedLength / 8) * 8);
        int[] encryptedInts = GTransformer.bytes2ints(encrypted2Ints);

        ByteBuffer resultBuffer = ByteBuffer.allocate(encryptedLength);

        for (int i = 0; i < encryptedInts.length; i += 2) {

            int delta = 0x9e3779b9;
            int sum = delta << 3;
            int a = encryptedInts[i];
            int b = encryptedInts[i + 1];

            for (int j = 0; j < 8; j++) {

                b -= (a << 4) + keyInts[2] ^ a + sum ^ (a >>> 5) + keyInts[3];
                a -= (b << 4) + keyInts[0] ^ b + sum ^ (b >>> 5) + keyInts[1];
                sum -= delta;
            }

            resultBuffer.putInt(a);
            resultBuffer.putInt(b);
        }

        resultBuffer.put(encrypted, encrypted2Ints.length, encryptedLength - encrypted2Ints.length);
        byte[] plain = resultBuffer.array();

        HFLog.d(TAG, String.format("[decrypt]\nencrypted: %s\nkey: %s\nplain: %s", GTransformer.bytes2HexStringWithWhitespace(encrypted), key,
                GTransformer.bytes2HexStringWithWhitespace(plain)));

        return plain;
    }
}

package hiflying.blelink;

public interface LinkingEncryptor {
    public byte[] encrypt(byte[] plain) throws Exception;

    public byte[] decrypt(byte[] encrypted) throws Exception;
}

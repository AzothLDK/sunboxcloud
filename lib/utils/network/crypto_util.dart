// ignore_for_file: constant_identifier_names

import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  static const int MAX_REQUEST_BODY_SIZE = 1048576; // 1MB
  static const String ENCRYPTION_ALGORITHM = "AES";
  static const String ENCRYPTION_MODE = "CBC";
  static const String ENCRYPTION_PADDING = "PKCS5Padding";
  // 偏移量
  static const String iv = "123456789asdfghj";
  // 密钥
  static const String key = "0123456789123456";

  // 解密请求体
  static String decryptRequest(String encryptedData) {
    if (encryptedData.isEmpty) {
      throw ArgumentError("Empty or null request body");
    }

    if (encryptedData.length > MAX_REQUEST_BODY_SIZE) {
      throw ArgumentError("Request body size exceeds the limit");
    }

    // 创建密钥和向量
    final keyBytes = Key.fromUtf8(key);
    final ivBytes = IV.fromUtf8(iv);

    // 创建加密器
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));

    // 解密数据
    final decrypted = encrypter.decrypt64(encryptedData, iv: ivBytes);
    return decrypted;
  }

  // 加密请求体
  static String encryptRequest(String plainText) {
    // 创建密钥和向量
    final keyBytes = Key.fromUtf8(key);
    final ivBytes = IV.fromUtf8(iv);
  
    // 创建加密器
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));
  
    // 加密数据
    final encrypted = encrypter.encrypt(plainText, iv: ivBytes);
    return encrypted.base64;
  }

  // Base64加密（用于其他可能的加密需求）
  static String encryptBase64(String randomStr) {
    final keyBytes = Key.fromUtf8("COMMONADMINLIIAN");
    final ivBytes = IV.fromLength(16);
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(randomStr, iv: ivBytes);
    return encrypted.base64;
  }
}

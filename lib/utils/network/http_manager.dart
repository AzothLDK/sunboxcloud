import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:sunboxcloud/controllers/auth_controller.dart';
import 'package:sunboxcloud/utils/storage.dart';

String _getAcceptLanguage() {
  final locale = Get.locale;
  if (locale != null) {
    return '${locale.languageCode}-${locale.countryCode ?? ''}';
  }
  return 'en-US';
}

Future<String> _getTimezone() async {
  try {
    return await FlutterTimezone.getLocalTimezone();
  } catch (e) {
    developer.log('Failed to get timezone: $e', name: 'HttpManager');
    return 'Asia/Shanghai';
  }
}

// const String host = "http://192.168.1.181:30742/";

const String host = "http://192.168.20.182:8001/";

class HttpManager {
  // 单例模式
  static final HttpManager _instance = HttpManager._internal();

  factory HttpManager() => _instance;

  late Dio _dio;

  static const String baseUrl = host; // API基础URL
  static const int connectTimeout = 15000; // 连接超时时间（毫秒）
  static const int receiveTimeout = 15000; // 接收超时时间（毫秒）

  HttpManager._internal() {
    // 初始化Dio
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: connectTimeout),
        receiveTimeout: const Duration(milliseconds: receiveTimeout),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        responseType: ResponseType.json,
      ),
    );

    // 添加请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 在请求发送前添加token
          String? token = GlobalStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token'; // 通常标准的做法是Bearer token，请根据实际后端要求修改
            options.headers['token'] = token; // 兼容旧逻辑
          }
          options.headers['Accept-Language'] = _getAcceptLanguage();
          options.headers['X-Timezone'] = await _getTimezone();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 对响应数据进行处理
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 处理请求错误
          return handler.next(e);
        },
      ),
    );

    // 添加日志拦截器，仅在 Debug 模式下开启
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (Object object) {
            developer.log(object.toString(), name: 'HttpManager');
          },
        ),
      );
    }
  }

  // GET请求
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // POST请求
  // 修改login方法，使用FormData
  // 修改 login 方法
  Future<Map<String, dynamic>> login(
    String path, {
    dynamic data, // 可以是JSON字符串或Map
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // 确保Content-Type是application/json
      Options requestOptions = options ?? Options();
      requestOptions.headers ??= {};
      requestOptions.headers!['Content-Type'] =
          'application/json; charset=utf-8';

      Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // 统一的POST请求
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // PUT请求
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      Response response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // DELETE请求
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      Response response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    String fileName = 'file',
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        if (data != null) ...data,
        fileName: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      Options requestOptions = options ?? Options();
      requestOptions.headers ??= {};
      requestOptions.headers!['Content-Type'] = 'multipart/form-data';

      Response response = await _dio.post(
        path,
        data: formData,
        options: requestOptions,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleUnknownError(e);
    }
  }

  // 统一处理成功响应
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // 处理认证失败或Token过期
        if (data['code'] == 401) {
          _handleTokenExpired();
        }
        return data;
      } else {
        return {'code': 200, 'msg': 'success', 'data': response.data};
      }
    } else {
      return {
        'code': response.statusCode ?? -1,
        'msg': response.statusMessage ?? '请求失败',
        'data': null,
      };
    }
  }

  // 处理 Dio 异常
  Map<String, dynamic> _handleError(DioException error) {
    String message;
    int code = -1;

    // 尝试从后端的错误响应中获取 msg (如认证失败的情况)
    if (error.response != null && error.response?.data is Map) {
      final responseData = error.response?.data as Map;
      if (responseData['code'] == 401) {
        _handleTokenExpired();
        return responseData as Map<String, dynamic>;
      }
      return {
        'code': responseData['code'] ?? error.response?.statusCode ?? -1,
        'msg':
            responseData['msg'] ??
            error.response?.statusMessage ??
            'server_error'.tr,
        'data': null,
      };
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'network_timeout'.tr;
        break;
      case DioExceptionType.connectionError:
        message = 'network_connection_failed'.tr;
        break;
      case DioExceptionType.cancel:
        message = 'request_cancelled'.tr;
        break;
      case DioExceptionType.badCertificate:
        message = 'certificate_error'.tr;
        break;
      case DioExceptionType.badResponse:
        code = error.response?.statusCode ?? -1;
        message = error.response?.statusMessage ?? 'server_error'.tr;
        break;
      case DioExceptionType.unknown:
        message = '${'unknown_error'.tr}: ${error.message}';
        break;
    }

    return {'code': code, 'msg': message, 'data': null};
  }

  // 处理未知异常
  Map<String, dynamic> _handleUnknownError(dynamic error) {
    developer.log(
      'Unknown Http Error: $error',
      name: 'HttpManager',
      error: error,
    );
    return {'code': -1, 'msg': 'unknown_error_occurred'.tr, 'data': null};
  }

  // 处理Token过期
  void _handleTokenExpired() {
    developer.log('Token expired or unauthorized', name: 'HttpManager');
    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        // 调用 logout 方法或其他清理操作
        // authController.logout();
        developer.log(
          'Found AuthController, ready to handle expiration',
          name: 'HttpManager',
        );
      }
      // 这里可选择是否自动弹窗提示
      // Get.snackbar('login_expired'.tr, 'please_login_again'.tr);
    } catch (e) {
      developer.log('Error handling token expiration: $e', name: 'HttpManager');
    }
  }

  // 获取原始Dio实例
  Dio get dio => _dio;

  // 更新BaseUrl
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }
}

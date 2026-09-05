import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DatabaseManager {
  final String _baseURL = "https://fostipresensiapi.vercel.app";

  final Dio _dio;
  final Duration _timeLimit;

  String _databaseStatus = '';

  DatabaseManager({this._timeLimit = const Duration(seconds: 10)}) : _dio = Dio();

  Future<bool> createData({
    required String endpoint,
    required Map<String, dynamic> jsonData,
    Map<String, String>? httpHeaders,
    bool showLogs = false,
  }) async {
    Uri url = Uri.parse("$_baseURL/$endpoint");
    bool isSuccess = false;

    try {
      String httpBody = jsonEncode(jsonData);
      final response = await _dio
          .post(
            url.toString(),
            options: Options(headers: httpHeaders),
            data: httpBody,
          )
          .timeout(_timeLimit);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _databaseStatus = 'POST ${url.toString()} -> OK (${response.statusCode})';
        isSuccess = true;
      } else {
        _databaseStatus = 'POST ${url.toString()} -> FAILURE (${response.statusCode})';
      }
    } on FormatException catch (fe) {
      _databaseStatus = 'JSON Format Error: $fe';
    } catch (e) {
      _databaseStatus = 'HTTP Error: $e';
    }

    if (kDebugMode && showLogs) {
      print(_databaseStatus);
    }

    return isSuccess;
  }

  Future<bool> updateData({
    required String endpoint,
    required String dataId,
    required Map<String, dynamic> jsonData,
    Map<String, String>? httpHeaders,
    bool showLogs = false,
  }) async {
    Uri url = Uri.parse("$_baseURL/$endpoint/$dataId");
    bool isSuccess = false;

    try {
      String httpBody = jsonEncode(jsonData);
      final response = await _dio
          .put(
            url.toString(),
            options: Options(headers: httpHeaders),
            data: httpBody,
          )
          .timeout(_timeLimit);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _databaseStatus = 'UPDATE ${url.toString()} -> OK (200)';
        isSuccess = true;
      } else {
        _databaseStatus = 'UPDATE ${url.toString()} -> FAILURE (${response.statusCode})';
      }
    } on FormatException catch (fe) {
      _databaseStatus = 'JSON Format Error: $fe';
    } catch (e) {
      _databaseStatus = 'HTTP Error: $e';
    }

    if (kDebugMode && showLogs) {
      print(_databaseStatus);
    }

    return isSuccess;
  }

  Future<bool> deleteData({
    required String endpoint,
    required String dataId,
    bool showLogs = false,
  }) async {
    Uri url = Uri.parse("$_baseURL/$endpoint/$dataId");
    bool isSuccess = false;

    try {
      final response = await _dio.delete(url.toString()).timeout(_timeLimit);
      if (response.statusCode == 200) {
        _databaseStatus = 'DELETE ${url.toString()} -> OK (200)';
        isSuccess = true;
      } else {
        _databaseStatus = 'DELETE ${url.toString()} -> FAILURE (${response.statusCode})';
      }
    } on FormatException catch (fe) {
      _databaseStatus = 'JSON Format Error: $fe';
    } catch (e) {
      _databaseStatus = 'HTTP Error: $e';
    }

    if (kDebugMode && showLogs) {
      print(_databaseStatus);
    }

    return isSuccess;
  }

  Future<Map<String, dynamic>> readData({
    required String endpoint,
    String? dataId,
    bool showLogs = false,
  }) async {
    Uri url = Uri.parse("$_baseURL/$endpoint/${dataId ?? ''}");
    Map<String, dynamic> responseResult = {};

    try {
      final response = await _dio.get(url.toString()).timeout(_timeLimit);
      final responseBody = response.data as Map<String, dynamic>;

      if (response.statusCode == 200) {
        responseResult = responseBody;
        _databaseStatus = 'GET ${url.toString()} -> OK (200)';
      } else if (response.statusCode == 404 ||
          (response.statusCode == 200 && responseBody.isEmpty)) {
        _databaseStatus = 'GET ${url.toString()} -> NOT FOUND (404)';
      } else {
        _databaseStatus = 'GET ${url.toString()} -> FAILURE (${response.statusCode})';
      }
    } on FormatException catch (fe) {
      _databaseStatus = 'JSON Format Error: $fe';
    } catch (e) {
      _databaseStatus = 'HTTP Error: $e';
    }

    if (kDebugMode && showLogs) {
      print(_databaseStatus);
    }

    return responseResult;
  }
}

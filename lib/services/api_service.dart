import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static const String apiUrl = ApiConfig.uploadUrl;

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();

      final responseData =
          await response.stream.bytesToString();

      print("API URL: $apiUrl");
      print("STATUS CODE: ${response.statusCode}");
      print("SERVER RESPONSE: $responseData");

      if (response.statusCode == 201 ||
          response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception(
          "Server Error ${response.statusCode}: $responseData",
        );
      }
    } catch (e) {
      print("API ERROR: $e");
      rethrow;
    }
  }
}
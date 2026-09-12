import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl =
      "http://192.168.43.30:8000/api/upload/";

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var response = await request.send();

      var responseData =
          await response.stream.bytesToString();

      print("STATUS CODE: ${response.statusCode}");
      print("SERVER RESPONSE: $responseData");

      if (response.statusCode == 201 || response.statusCode == 200) {
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
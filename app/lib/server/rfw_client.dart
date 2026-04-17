import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import 'package:rfw_sample/config/server_config.dart';

class RfwClientException implements Exception {
  const RfwClientException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RfwClient {
  const RfwClient._();

  static Future<RemoteWidgetLibrary> fetchWidget(String name) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}/widgets/$name');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw RfwClientException('Widget "$name" の取得に失敗しました (${response.statusCode})');
    }
    return decodeLibraryBlob(response.bodyBytes);
  }

  static Future<List<Map<String, String>>> fetchProducts() async {
    final uri = Uri.parse('${ServerConfig.baseUrl}/data/products');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw RfwClientException('商品データの取得に失敗しました (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
        .toList();
  }
}

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

class ScreenConfig {
  const ScreenConfig({required this.widgetName, required this.library, required this.data});

  final String widgetName;
  final RemoteWidgetLibrary library;
  final Map<String, String> data;
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

  /// サーバーが選んだウィジェット定義＋データを一度に取得する。
  /// 本番では user_id・時間帯などをヘッダーで渡し、サーバー側の selectVariant が判断する。
  static Future<ScreenConfig> fetchScreen(String name) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}/screen/$name');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw RfwClientException('Screen "$name" の取得に失敗しました (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final widgetName = json['widget'] as String;
    final data = (json['data'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v.toString()),
    );

    final library = await fetchWidget(widgetName);
    return ScreenConfig(widgetName: widgetName, library: library, data: data);
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

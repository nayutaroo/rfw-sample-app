import 'dart:io';

class ServerConfig {
  const ServerConfig._();

  // Android エミュレーターからホストの localhost へは 10.0.2.2 でアクセス
  static String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
}

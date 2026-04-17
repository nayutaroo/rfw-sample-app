import 'dart:io';

import 'package:rfw/formats.dart';

Future<void> main() async {
  // スクリプトの場所から pjルートを解決する
  // bin/generate_rfw.dart → generate_rfw/ → tools/ → project root
  final projectRoot = File(Platform.script.toFilePath()).parent.parent.parent.parent;

  final sourceDir = Directory('${projectRoot.path}/server/rfw');
  final outputDir = Directory('${projectRoot.path}/server/static');

  if (!sourceDir.existsSync()) {
    stderr.writeln('Source directory not found: ${sourceDir.path}');
    exit(1);
  }

  outputDir.createSync(recursive: true);

  var count = 0;
  await for (final entity in sourceDir.list()) {
    if (entity is! File || !entity.path.endsWith('.rfwtxt')) continue;

    final text = await entity.readAsString();
    final library = parseLibraryFile(text);
    final binary = encodeLibraryBlob(library);

    final name = entity.uri.pathSegments.last.replaceAll('.rfwtxt', '');
    final output = File('${outputDir.path}/$name.rfw');
    await output.writeAsBytes(binary);
    stdout.writeln('Generated: ${output.path}');
    count++;
  }

  stdout.writeln('Done. $count file(s) generated.');
}

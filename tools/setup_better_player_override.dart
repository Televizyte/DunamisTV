import 'dart:io';

void main() {
  final projectRoot = Directory.current.path;
  final localAppData = Platform.environment['LOCALAPPDATA'];

  if (localAppData == null || localAppData.isEmpty) {
    stderr.writeln('[ERROR] LOCALAPPDATA not found. This script is for Windows.');
    exit(1);
  }

  final cache1 = Directory('$localAppData\\Pub\\Cache\\hosted\\pub.dev\\better_player-0.0.84');
  final cache2 = Directory('$localAppData\\Pub\\Cache\\hosted\\pub.dartlang.org\\better_player-0.0.84');

  final src = cache1.existsSync() ? cache1 : (cache2.existsSync() ? cache2 : null);
  if (src == null) {
    stderr.writeln('[ERROR] better_player-0.0.84 not found in Pub cache. Run `flutter pub get` first.');
    exit(1);
  }

  final thirdPartyDir = Directory('$projectRoot\\third_party');
  final dst = Directory('${thirdPartyDir.path}\\better_player');

  if (!thirdPartyDir.existsSync()) thirdPartyDir.createSync(recursive: true);
  if (dst.existsSync()) {
    stdout.writeln('[INFO] Removing existing local override: ${dst.path}');
    dst.deleteSync(recursive: true);
  }

  stdout.writeln('[INFO] Copying from cache: ${src.path}');
  copyDir(src, dst);

  final patched = patchDartFiles(dst);
  stdout.writeln('[INFO] Patched $patched Dart file(s) in local override.');

  final pubspec = File('${dst.path}\\pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('[ERROR] Local override incomplete: missing ${pubspec.path}');
    exit(1);
  }

  stdout.writeln('\n=== SUCCESS ===');
  stdout.writeln('Local override created at: third_party/better_player');
  stdout.writeln('Now run:');
  stdout.writeln('  flutter clean');
  stdout.writeln('  flutter pub get');
  stdout.writeln('  flutter run -d chrome');
}

void copyDir(Directory src, Directory dst) {
  dst.createSync(recursive: true);

  for (final entity in src.listSync(recursive: false, followLinks: false)) {
    final name = entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : '';
    if (name.isEmpty) continue;

    if (entity is File) {
      final out = File('${dst.path}\\$name');
      out.writeAsBytesSync(entity.readAsBytesSync());
    } else if (entity is Directory) {
      copyDir(entity, Directory('${dst.path}\\$name'));
    }
  }
}

int patchDartFiles(Directory root) {
  var changedCount = 0;

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final before = entity.readAsStringSync();
    var after = before.replaceAll('hashValues(', 'Object.hash(');
    after = after.replaceAll('hashList(', 'Object.hashAll(');

    if (after != before) {
      entity.writeAsStringSync(after);
      changedCount++;
      stdout.writeln('[PATCHED] ${entity.path}');
    }
  }

  return changedCount;
}

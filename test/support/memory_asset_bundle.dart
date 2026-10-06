import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class MemoryAssetBundle extends AssetBundle {
  MemoryAssetBundle(this._strings);

  final Map<String, String> _strings;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(await loadString(key)),
    );
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final String? source = _strings[key];
    if (source == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return source;
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async {
    return parser(await loadString(key));
  }
}

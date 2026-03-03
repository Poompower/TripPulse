import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/place.dart';

class WikimediaImageService {
  static final WikimediaImageService instance = WikimediaImageService._();

  WikimediaImageService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final Map<String, String?> _resolvedCache = {};
  final Map<String, Future<String?>> _pending = {};

  Future<String?> resolveImageUrl(Place place) {
    if (place.imageUrl != null && place.imageUrl!.isNotEmpty) {
      return Future.value(place.imageUrl);
    }

    final key =
        '${place.id}|${place.wikimediaCommons ?? ''}|${place.wikipediaTitle ?? ''}';
    if (_resolvedCache.containsKey(key)) {
      return Future.value(_resolvedCache[key]);
    }
    if (_pending.containsKey(key)) {
      return _pending[key]!;
    }

    final future = _resolveInternal(place).then((value) {
      developer.log(
        'Resolved image for placeId=${place.id} source=${value == null ? 'none' : 'wiki'}',
        name: 'WikimediaImage',
      );
      _resolvedCache[key] = value;
      _pending.remove(key);
      return value;
    });
    _pending[key] = future;
    return future;
  }

  Future<String?> _resolveInternal(Place place) async {
    final commons = place.wikimediaCommons;
    if (commons != null && commons.isNotEmpty) {
      developer.log(
        'Try commons source=$commons placeId=${place.id}',
        name: 'WikimediaImage',
      );
      if (commons.startsWith('File:')) {
        return _commonsFilePathUrl(commons);
      }
      if (commons.startsWith('Category:')) {
        final fromCategory = await _resolveFromCommonsCategory(commons);
        if (fromCategory != null) return fromCategory;
      }
    }

    final wiki = place.wikipediaTitle;
    if (wiki != null && wiki.isNotEmpty) {
      developer.log(
        'Try wikipedia source=$wiki placeId=${place.id}',
        name: 'WikimediaImage',
      );
      final fromWikipedia = await _resolveFromWikipediaTitle(wiki);
      if (fromWikipedia != null) return fromWikipedia;
    }

    developer.log(
      'No wiki metadata for placeId=${place.id}, fallback to title search',
      name: 'WikimediaImage',
    );
    final fromSearch = await _resolveFromWikipediaSearch(place);
    if (fromSearch != null) return fromSearch;

    return null;
  }

  String _commonsFilePathUrl(String fileName) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(fileName)}';
  }

  Future<String?> _resolveFromCommonsCategory(String category) async {
    try {
      final response = await _dio.get(
        'https://commons.wikimedia.org/w/api.php',
        queryParameters: {
          'action': 'query',
          'generator': 'categorymembers',
          'gcmtitle': category,
          'gcmtype': 'file',
          'gcmlimit': 1,
          'prop': 'imageinfo',
          'iiprop': 'url',
          'format': 'json',
        },
      );

      final pages = response.data['query']?['pages'];
      if (pages is! Map) return null;

      for (final value in pages.values) {
        final map = value as Map<String, dynamic>;
        final info = map['imageinfo'];
        if (info is List && info.isNotEmpty) {
          final first = info.first;
          if (first is Map<String, dynamic>) {
            final url = first['url']?.toString();
            if (url != null && url.isNotEmpty) return url;
          }
        }
      }

      return null;
    } catch (e, st) {
      developer.log(
        'Commons category lookup failed: $category',
        name: 'WikimediaImage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> _resolveFromWikipediaTitle(String wikipediaTitle) async {
    final parts = wikipediaTitle.split(':');
    final hasLangPrefix = parts.length > 1;
    final lang = hasLangPrefix ? parts.first : 'en';
    final title = hasLangPrefix ? parts.sublist(1).join(':') : wikipediaTitle;
    if (title.trim().isEmpty) return null;

    try {
      final response = await _dio.get(
        'https://$lang.wikipedia.org/w/api.php',
        queryParameters: {
          'action': 'query',
          'titles': title,
          'prop': 'pageimages',
          'pithumbsize': 700,
          'format': 'json',
        },
      );

      final pages = response.data['query']?['pages'];
      if (pages is! Map) return null;

      for (final value in pages.values) {
        final map = value as Map<String, dynamic>;
        final thumbnail = map['thumbnail'];
        if (thumbnail is Map<String, dynamic>) {
          final source = thumbnail['source']?.toString();
          if (source != null && source.isNotEmpty) return source;
        }
      }

      return null;
    } catch (e, st) {
      developer.log(
        'Wikipedia thumbnail lookup failed: $wikipediaTitle',
        name: 'WikimediaImage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> _resolveFromWikipediaSearch(Place place) async {
    final queries = <String>[
      if (place.country != null && place.country!.isNotEmpty)
        '${place.name} ${place.country}',
      place.name,
    ];

    for (final query in queries) {
      for (final lang in const ['th', 'en']) {
        try {
          final searchResponse = await _dio.get(
            'https://$lang.wikipedia.org/w/api.php',
            queryParameters: {
              'action': 'query',
              'list': 'search',
              'srsearch': query,
              'srlimit': 1,
              'format': 'json',
            },
          );

          final searchList = searchResponse.data['query']?['search'];
          if (searchList is! List || searchList.isEmpty) continue;

          final first = searchList.first;
          if (first is! Map<String, dynamic>) continue;

          final title = first['title']?.toString();
          if (title == null || title.isEmpty) continue;

          final thumbnail = await _resolveFromWikipediaTitle('$lang:$title');
          if (thumbnail != null && thumbnail.isNotEmpty) {
            developer.log(
              'Resolved via wikipedia search lang=$lang query="$query" title="$title"',
              name: 'WikimediaImage',
            );
            return thumbnail;
          }
        } catch (e, st) {
          developer.log(
            'Wikipedia search failed lang=$lang query="$query"',
            name: 'WikimediaImage',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    return null;
  }
}

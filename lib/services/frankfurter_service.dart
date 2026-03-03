import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'database_service.dart';

class CurrencyOption {
  final String code;
  final String name;

  const CurrencyOption({required this.code, required this.name});
}

class FrankfurterService {
  static const Map<String, String> supportedCurrencies = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'AED': 'UAE Dirham',
    'SGD': 'Singapore Dollar',
    'THB': 'Thai Baht',
  };

  final DatabaseService _databaseService = DatabaseService();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.frankfurter.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  Future<List<CurrencyOption>> fetchCurrencies() async {
    const endpoint = '/currencies';
    const maxAttempts = 2;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      developer.log(
        'Request start GET $endpoint attempt=$attempt/$maxAttempts',
        name: 'FrankfurterAPI',
      );

      try {
        final response = await _dio.get(endpoint);
        developer.log(
          'Response status=${response.statusCode} for $endpoint',
          name: 'FrankfurterAPI',
        );

        final data = response.data;
        if (data is! Map<String, dynamic>) {
          developer.log(
            'Invalid response format: ${data.runtimeType}',
            name: 'FrankfurterAPI',
          );
          throw Exception('Unexpected currency response format');
        }

        final currencies =
            data.entries
                .map(
                  (entry) => CurrencyOption(
                    code: entry.key,
                    name: entry.value.toString(),
                  ),
                )
                .toList()
              ..sort((a, b) => a.code.compareTo(b.code));

        developer.log(
          'Parsed ${currencies.length} currencies',
          name: 'FrankfurterAPI',
        );
        return currencies;
      } on DioException catch (e) {
        developer.log(
          'Request failed $endpoint attempt=$attempt status=${e.response?.statusCode} message=${e.message}',
          name: 'FrankfurterAPI',
          error: e,
        );

        if (attempt == maxAttempts) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
      } catch (e, st) {
        developer.log(
          'Unexpected error while fetching currencies: $e',
          name: 'FrankfurterAPI',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
    }

    throw Exception('Unable to fetch currencies');
  }

  Future<List<CurrencyOption>> fetchSupportedCurrencies() async {
    final cached = await _databaseService.getCurrencyCache();
    final now = DateTime.now();

    if (cached != null && cached.currencies.isNotEmpty) {
      final updatedAt = cached.updatedAt;
      final isFresh =
          updatedAt != null &&
          now.difference(updatedAt) < const Duration(days: 7);
      if (isFresh) {
        developer.log(
          'Using cached currencies (fresh, <7 days)',
          name: 'FrankfurterAPI',
        );
        return cached.currencies.entries
            .map((entry) => CurrencyOption(code: entry.key, name: entry.value))
            .toList();
      }
    }

    try {
      final currencies = await fetchCurrencies();
      final byCode = {for (final item in currencies) item.code: item};

      final filtered = supportedCurrencies.keys
          .where(byCode.containsKey)
          .map((code) => byCode[code]!)
          .toList();

      if (filtered.isNotEmpty) {
        await _databaseService.upsertCurrencyCache(
          currencies: {for (final item in filtered) item.code: item.name},
          updatedAt: now,
        );
      }

      return filtered;
    } catch (e, st) {
      if (cached != null && cached.currencies.isNotEmpty) {
        developer.log(
          'Using cached currencies (stale) after API failure',
          name: 'FrankfurterAPI',
          error: e,
        );
        return cached.currencies.entries
            .map((entry) => CurrencyOption(code: entry.key, name: entry.value))
            .toList();
      }

      developer.log(
        'Using bundled fallback currencies after API failure',
        name: 'FrankfurterAPI',
        error: e,
        stackTrace: st,
      );

      return supportedCurrencies.entries
          .map((entry) => CurrencyOption(code: entry.key, name: entry.value))
          .toList();
    }
  }
}

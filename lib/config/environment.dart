import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get geoapifyApiKey => dotenv.env['GEOAPIFY_API_KEY'] ?? '';
}

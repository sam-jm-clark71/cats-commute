import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tfl_status.dart';

class TflService {
  static const _url = 'https://api.tfl.gov.uk/Line/northern/Status';

  Future<TflLineStatus> fetchNorthernLineStatus() async {
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return TflLineStatus.unknown();
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return TflLineStatus.unknown();

      return TflLineStatus.fromJson(data.first as Map<String, dynamic>);
    } catch (_) {
      return TflLineStatus.unknown();
    }
  }
}

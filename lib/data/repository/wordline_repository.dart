import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:simar/data/model/wordline_reply.dart';

class WordlineRepository {
  final String apiURL =
      'https://itabsa.apis.svc.as8677.net/api/mobile?eStamps=';

  Future<WordLineReply?> retrieveWordLineReply(String um) async {
    http.Client client = http.Client();

    final response = await client.get(Uri.parse(apiURL + um));

    if (response.statusCode == 200) {
      String decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> parsed = json.decode(decoded);
      WordLineReply reply = WordLineReply.fromMap(parsed);
      client.close();
      return reply;
    } else {
      return null;
    }
  }
}

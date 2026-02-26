import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final projectId = 'finance-manager-2026-stg';
  final url =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/accounts';

  try {
    print('Fetching accounts from $url ...');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print('--- Success ---');
      final data = jsonDecode(response.body);

      final docs = data['documents'] as List<dynamic>?;
      if (docs == null) {
        print('No documents found.');
        return;
      }
      for (var doc in docs) {
        final name = doc['name'];
        final fields = doc['fields'];
        print('Doc: $name');
        print(' Fields: $fields');
      }
    } else {
      print('--- Failed ---');
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

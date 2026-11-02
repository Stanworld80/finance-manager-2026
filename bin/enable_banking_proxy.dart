import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Local CORS Proxy for Enable Banking API when running FinanceManager2026 on Flutter Web.
///
/// Usage:
///   dart run bin/enable_banking_proxy.dart
///
/// Then set Proxy URL in the app's Enable Banking configuration to:
///   http://localhost:8787
Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? (int.tryParse(args.first) ?? 8787) : 8787;
  const targetOrigin = 'https://api.enablebanking.com';
  final client = http.Client();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'Enable Banking CORS Proxy actif sur http://localhost:$port -> $targetOrigin',
  );

  await for (final HttpRequest req in server) {
    _addCorsHeaders(req.response);

    if (req.method.toUpperCase() == 'OPTIONS') {
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      continue;
    }

    try {
      final targetUri = Uri.parse(targetOrigin).replace(
        path: req.uri.path,
        query: req.uri.query.isEmpty ? null : req.uri.query,
      );

      final bodyBytes = await req.fold<List<int>>(
        <int>[],
        (prev, element) => prev..addAll(element),
      );

      final forwardHeaders = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final authHeader = req.headers.value('authorization');
      if (authHeader != null) {
        forwardHeaders['Authorization'] = authHeader;
      }
      req.headers.forEach((name, values) {
        if (name.toLowerCase().startsWith('psu-') && values.isNotEmpty) {
          forwardHeaders[name] = values.first;
        }
      });

      final forwardReq = http.Request(req.method, targetUri)
        ..headers.addAll(forwardHeaders)
        ..bodyBytes = bodyBytes;

      final streamedRes = await client.send(forwardReq);
      final resBytes = await streamedRes.stream.toBytes();

      req.response.statusCode = streamedRes.statusCode;
      req.response.headers.contentType = ContentType.json;
      req.response.add(resBytes);
      await req.response.close();
    } catch (e) {
      req.response.statusCode = HttpStatus.badGateway;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'error': 'PROXY_ERROR', 'message': '$e'}));
      await req.response.close();
    }
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, DELETE, OPTIONS',
  );
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Origin, Content-Type, Accept, Authorization, Psu-Ip-Address, Psu-User-Agent',
  );
}

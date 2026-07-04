import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Finance MCP Server Tests', () {
    late Process process;
    late Stream<String> stdoutLines;
    int requestId = 1;
    final testDbPath = p.join(Directory.systemTemp.path, 'mcp_test_finance.db');

    setUp(() async {
      // Ensure clean start
      final file = File(testDbPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }

      // Start the MCP server process
      process = await Process.start(
        'dart',
        ['bin/mcp_server.dart'],
        runInShell: true,
        environment: {
          'FINANCE_DB_PATH': testDbPath,
        },
      );
      process.stderr.transform(utf8.decoder).listen((error) {
        print("MCP Server STDERR: $error");
      });
      stdoutLines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();
    });

    tearDown(() async {
      process.kill();
      await process.exitCode;
      
      final file = File(testDbPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    });

    Future<Map<String, dynamic>> sendRequest(String method, Map<String, dynamic> params) async {
      final reqId = requestId++;
      final request = {
        'jsonrpc': '2.0',
        'id': reqId,
        'method': method,
        'params': params,
      };

      process.stdin.writeln(jsonEncode(request));
      await process.stdin.flush();

      // Read response, skipping non-JSON lines
      await for (final line in stdoutLines) {
        if (line.trim().startsWith('{')) {
          final response = jsonDecode(line) as Map<String, dynamic>;
          if (response['id'] == reqId) {
            return response;
          }
        }
      }
      throw Exception("No response received for request $reqId");
    }

    test('Should initialize correctly', () async {
      final res = await sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
      });

      expect(res.containsKey('result'), true);
      expect(res['result']['protocolVersion'], '2024-11-05');
      expect(res['result']['serverInfo']['name'], 'finance-manager-mcp-server');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Should list tools', () async {
      // Initialize first
      await sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
      });

      final res = await sendRequest('tools/list', {});
      final result = res['result'] as Map<String, dynamic>;
      final tools = result['tools'] as List<dynamic>;

      expect(tools.length, 3);
      expect(tools[0]['name'], 'get_balances');
      expect(tools[1]['name'], 'add_transaction');
      expect(tools[2]['name'], 'suggest_matches');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Should suggest matches', () async {
      // Initialize first
      await sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
      });

      final res = await sendRequest('tools/call', {
        'name': 'suggest_matches',
        'arguments': {
          'amount': 100.0,
          'description': 'test',
          'transactionDate': DateTime.now().toIso8601String(),
        }
      });

      final result = res['result'] as Map<String, dynamic>;
      final content = result['content'] as List<dynamic>;
      expect(content[0]['type'], 'text');
      expect(content[0]['text'].contains('No matching transaction'), true);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

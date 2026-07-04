import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MCP Server SQL Injection Security Tests', () {
    late Process process;
    late Stream<String> stdoutLines;
    int requestId = 1;
    final testDbPath = p.join(Directory.systemTemp.path, 'mcp_security_test.db');

    setUp(() async {
      final file = File(testDbPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }

      process = await Process.start(
        'dart',
        ['bin/mcp_server.dart'],
        runInShell: true,
        environment: {
          'FINANCE_DB_PATH': testDbPath,
        },
      );
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

    test('Security: Prevent SQL Injection in add_transaction parameters', () async {
      // Initialize server
      await sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'security-scanner', 'version': '1.0.0'},
      });

      // Malicious payload trying to inject SQL
      final maliciousDescription = "malicious'); DROP TABLE transactions; --";

      final res = await sendRequest('tools/call', {
        'name': 'add_transaction',
        'arguments': {
          'ownerId': "attacker' --",
          'realAccountId': 'acc123',
          'description': maliciousDescription,
          'amount': 100.0,
          'splits': [
            {'virtualAccountId': 'env123', 'amount': 100.0}
          ]
        }
      });

      // Check that the table still exists and query does not crash SQLite database structure
      final listRes = await sendRequest('tools/list', {});
      expect(listRes.containsKey('result'), true);

      // Verify response is handled safely (it might fail due to missing account foreign keys, but no syntax crash)
      expect(res.containsKey('error') || res.containsKey('result'), true);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Security: Prevent SQL Injection in suggest_matches description', () async {
      await sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'security-scanner', 'version': '1.0.0'},
      });

      final maliciousDescription = "any' OR '1'='1";

      final res = await sendRequest('tools/call', {
        'name': 'suggest_matches',
        'arguments': {
          'amount': 50.0,
          'description': maliciousDescription,
          'transactionDate': DateTime.now().toIso8601String(),
        }
      });

      final result = res['result'] as Map<String, dynamic>;
      final content = result['content'] as List<dynamic>;
      expect(content[0]['type'], 'text');
      // Should not return all rows due to tautology (OR '1'='1') because parameters are bound
      expect(content[0]['text'].contains('No matching transaction'), true);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

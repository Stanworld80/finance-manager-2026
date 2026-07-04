import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() async {
  final dbPath = _getDatabasePath();
  final server = McpServer(dbPath);
  server.start();
}

String _getDatabasePath() {
  final envPath = Platform.environment['FINANCE_DB_PATH'];
  if (envPath != null) return envPath;

  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  return p.join(home, 'Documents', 'finance_manager.db');
}

class McpServer {
  final String dbPath;
  late final Database _db;
  bool _initialized = false;

  McpServer(this.dbPath) {
    try {
      final file = File(dbPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      _db = sqlite3.open(dbPath);
      _initializeSchemaIfNeeded();
    } catch (e) {
      _logError("Failed to open database at $dbPath: $e");
      exit(1);
    }
  }

  void _initializeSchemaIfNeeded() {
    // Create tables if they don't exist (fallback when starting without Flutter)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS real_accounts (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        bank_name TEXT,
        initial_balance REAL NOT NULL DEFAULT 0.0,
        balance REAL NOT NULL DEFAULT 0.0,
        type TEXT NOT NULL,
        is_principal INTEGER NOT NULL DEFAULT 0,
        shared_with_user_ids TEXT NOT NULL,
        opening_date TEXT,
        account_number TEXT,
        official_name TEXT,
        iban TEXT,
        bic TEXT,
        swift TEXT,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS virtual_accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        real_account_id TEXT NOT NULL,
        name TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        type TEXT NOT NULL,
        icon TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(real_account_id) REFERENCES real_accounts(id) ON DELETE CASCADE
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        real_account_id TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        value_date TEXT,
        visibility_date TEXT,
        matching_date TEXT,
        step TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(real_account_id) REFERENCES real_accounts(id) ON DELETE CASCADE
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_splits (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        virtual_account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY(virtual_account_id) REFERENCES virtual_accounts(id) ON DELETE CASCADE
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  void start() {
    _logError("Finance MCP Server listening on stdio (DB: $dbPath)...");

    stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isEmpty) return;
      try {
        final request = jsonDecode(line) as Map<String, dynamic>;
        _handleRequest(request);
      } catch (e) {
        _sendError(null, -32700, "Parse error: $e");
      }
    });
  }

  void _handleRequest(Map<String, dynamic> req) {
    final id = req['id'];
    final method = req['method'] as String?;

    if (method == null) {
      _sendError(id, -32600, "Invalid Request: missing method");
      return;
    }

    // JSON-RPC lifecycle
    if (!_initialized && method != 'initialize') {
      _sendError(id, -32002, "Server not initialized");
      return;
    }

    switch (method) {
      case 'initialize':
        _initialized = true;
        _sendResponse(id, {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {'listChanged': false},
            'resources': {'listChanged': false}
          },
          'serverInfo': {
            'name': 'finance-manager-mcp-server',
            'version': '1.0.0'
          }
        });
        break;

      case 'notifications/initialized':
        // Client confirms initialization (notification: no response)
        break;

      case 'tools/list':
        _sendResponse(id, {
          'tools': [
            {
              'name': 'get_balances',
              'description': 'Retrieve balances of all real bank accounts and virtual budget envelopes.',
              'inputSchema': {
                'type': 'object',
                'properties': {},
              }
            },
            {
              'name': 'add_transaction',
              'description': 'Create a double-entry balanced transaction across real and virtual accounts.',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'ownerId': {'type': 'string', 'description': 'User ID of the transaction owner.'},
                  'realAccountId': {'type': 'string', 'description': 'The real bank account ID.'},
                  'description': {'type': 'string', 'description': 'Description of the transaction.'},
                  'amount': {'type': 'number', 'description': 'Total amount. Negative for expenses, positive for income.'},
                  'splits': {
                    'type': 'array',
                    'description': 'List of envelopes impacted by the transaction. Total sum must match the transaction amount.',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'virtualAccountId': {'type': 'string'},
                        'amount': {'type': 'number'}
                      },
                      'required': ['virtualAccountId', 'amount']
                    }
                  }
                },
                'required': ['ownerId', 'realAccountId', 'description', 'amount', 'splits']
              }
            },
            {
              'name': 'suggest_matches',
              'description': 'Suggest matching unmatched virtual/planned transactions for a real bank transaction.',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'amount': {'type': 'number', 'description': 'The amount of the real transaction to match.'},
                  'description': {'type': 'string', 'description': 'The description/label of the real transaction.'},
                  'transactionDate': {'type': 'string', 'description': 'ISO 8601 date of the real transaction.'},
                  'maxDaysDifference': {'type': 'integer', 'description': 'Maximum date difference in days (default: 7).'}
                },
                'required': ['amount']
              }
            }
          ]
        });
        break;

      case 'tools/call':
        final params = req['params'] as Map<String, dynamic>? ?? {};
        final name = params['name'] as String?;
        final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
        _handleToolCall(id, name, arguments);
        break;

      default:
        _sendError(id, -32601, "Method not found");
    }
  }

  void _handleToolCall(dynamic id, String? name, Map<String, dynamic> args) {
    if (name == 'get_balances') {
      try {
        final realResults = _db.select('SELECT id, name, bank_name, balance, type FROM real_accounts');
        final virtualResults = _db.select('SELECT id, real_account_id, name, balance, type FROM virtual_accounts');

        final buffer = StringBuffer();
        buffer.writeln("=== REAL BANK ACCOUNTS ===");
        for (final row in realResults) {
          buffer.writeln("- [${row['id']}] ${row['name']} (${row['bank_name'] ?? 'Unknown Bank'}): ${row['balance']} EUR (${row['type']})");
        }
        buffer.writeln("\n=== VIRTUAL ENVELOPES ===");
        for (final row in virtualResults) {
          buffer.writeln("- [${row['id']}] ${row['name']} (Real: ${row['real_account_id']}): ${row['balance']} EUR (${row['type']})");
        }

        _sendToolResult(id, buffer.toString());
      } catch (e) {
        _sendToolError(id, "Failed to fetch balances: $e");
      }
    } else if (name == 'add_transaction') {
      try {
        final ownerId = args['ownerId'] as String;
        final realAccountId = args['realAccountId'] as String;
        final description = args['description'] as String;
        final amount = (args['amount'] as num).toDouble();
        final splitsList = args['splits'] as List<dynamic>;

        // Double-entry validation: sum of splits must match amount
        double splitSum = 0.0;
        for (final split in splitsList) {
          splitSum += (split['amount'] as num).toDouble();
        }

        if ((splitSum - amount).abs() > 0.001) {
          _sendToolError(id, "Double-entry violation: splits sum ($splitSum) must equal transaction amount ($amount)");
          return;
        }

        final txId = DateTime.now().millisecondsSinceEpoch.toString();
        final nowStr = DateTime.now().toIso8601String();

        _db.execute('BEGIN TRANSACTION;');

        try {
          // 1. Insert transaction
          _db.execute(
            'INSERT INTO transactions (id, owner_id, real_account_id, description, amount, transaction_date, step, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [txId, ownerId, realAccountId, description, amount, nowStr, 'effectue', 'provisionne', nowStr, nowStr],
          );

          // 2. Update real account balance
          _db.execute(
            'UPDATE real_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [amount, nowStr, realAccountId],
          );

          // 3. Process splits
          final payloadSplits = [];
          for (final split in splitsList) {
            final splitId = '${txId}_${split['virtualAccountId']}';
            final splitAmount = (split['amount'] as num).toDouble();
            final virtualAccountId = split['virtualAccountId'] as String;

            _db.execute(
              'INSERT INTO transaction_splits (id, transaction_id, virtual_account_id, amount) VALUES (?, ?, ?, ?)',
              [splitId, txId, virtualAccountId, splitAmount],
            );

            // Update virtual account balance
            _db.execute(
              'UPDATE virtual_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
              [splitAmount, nowStr, virtualAccountId],
            );

            payloadSplits.add({
              'id': splitId,
              'virtualAccountId': virtualAccountId,
              'amount': splitAmount,
            });
          }

          // 4. Log in sync outbox for Flutter app to sync with Firestore later
          final payload = {
            'id': txId,
            'ownerId': ownerId,
            'realAccountId': realAccountId,
            'description': description,
            'amount': amount,
            'transactionDate': nowStr,
            'step': 'effectue',
            'status': 'provisionne',
            'createdAt': nowStr,
            'updatedAt': nowStr,
            'splits': payloadSplits,
          };

          _db.execute(
            'INSERT INTO sync_outbox (table_name, record_id, action, payload, created_at) VALUES (?, ?, ?, ?, ?)',
            ['transactions', txId, 'INSERT', jsonEncode(payload), nowStr],
          );

          _db.execute('COMMIT;');
          _sendToolResult(id, "Transaction successfully added (ID: $txId) and balances updated.");
        } catch (e) {
          _db.execute('ROLLBACK;');
          rethrow;
        }
      } catch (e) {
        _sendToolError(id, "Failed to add transaction: $e");
      }
    } else if (name == 'suggest_matches') {
      try {
        final amount = (args['amount'] as num).toDouble();
        final description = args['description'] as String?;
        final dateStr = args['transactionDate'] as String?;
        final maxDays = args['maxDaysDifference'] as int? ?? 7;

        final targetDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

        // Fetch planned/unmatched transactions
        final results = _db.select('SELECT id, real_account_id, description, amount, transaction_date FROM transactions WHERE matching_date IS NULL');

        final candidates = <Map<String, dynamic>>[];

        for (final row in results) {
          final txAmount = row['amount'] as double;
          final txDate = DateTime.tryParse(row['transaction_date'] as String);
          final txDescription = row['description'] as String;

          // 1. Amount match (allowing small floating point difference)
          if ((txAmount.abs() - amount.abs()).abs() > 0.01) {
            continue;
          }

          // 2. Date match
          int daysDiff = 0;
          if (targetDate != null && txDate != null) {
            daysDiff = txDate.difference(targetDate).inDays.abs();
            if (daysDiff > maxDays) {
              continue;
            }
          }

          // 3. Compute match score
          double score = 1.0; // Base score for amount match

          // Date closeness bonus
          if (targetDate != null && txDate != null) {
            score += (maxDays - daysDiff) / maxDays; // Up to +1.0
          }

          // Text similarity bonus
          if (description != null) {
            final descLower = description.toLowerCase();
            final txDescLower = txDescription.toLowerCase();
            if (txDescLower == descLower) {
              score += 2.0; // Exact match
            } else if (txDescLower.contains(descLower) || descLower.contains(txDescLower)) {
              score += 1.0; // Substring match
            } else {
              // Word overlap
              final words1 = descLower.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
              final words2 = txDescLower.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
              final intersection = words1.intersection(words2);
              if (intersection.isNotEmpty) {
                score += 0.5 * intersection.length;
              }
            }
          }

          candidates.add({
            'id': row['id'],
            'realAccountId': row['real_account_id'],
            'description': txDescription,
            'amount': txAmount,
            'transactionDate': row['transaction_date'],
            'score': score,
          });
        }

        // Sort by score descending
        candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

        final buffer = StringBuffer();
        if (candidates.isEmpty) {
          buffer.writeln("No matching transaction candidates found in local database.");
        } else {
          buffer.writeln("=== MATCHING CANDIDATES FOUND ===");
          for (final c in candidates) {
            buffer.writeln("- [${c['id']}] ${c['description']} (${c['transactionDate']}): ${c['amount']} EUR (Score: ${c['score'].toStringAsFixed(2)})");
          }
        }

        _sendToolResult(id, buffer.toString());
      } catch (e) {
        _sendToolError(id, "Failed to suggest matches: $e");
      }
    } else {
      _sendError(id, -32601, "Tool not found");
    }
  }

  void _sendResponse(dynamic id, Map<String, dynamic> result) {
    print(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'result': result
    }));
  }

  void _sendError(dynamic id, int code, String msg) {
    print(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': msg}
    }));
  }

  void _sendToolResult(dynamic id, String text) {
    _sendResponse(id, {
      'content': [
        {'type': 'text', 'text': text}
      ]
    });
  }

  void _sendToolError(dynamic id, String errorMsg) {
    _sendResponse(id, {
      'isError': true,
      'content': [
        {'type': 'text', 'text': errorMsg}
      ]
    });
  }

  void _logError(String msg) {
    stderr.writeln(msg);
  }
}

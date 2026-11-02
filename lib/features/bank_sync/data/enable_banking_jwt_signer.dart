import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class RsaPrivateKeyParameters {
  final BigInt modulus;
  final BigInt publicExponent;
  final BigInt privateExponent;

  const RsaPrivateKeyParameters({
    required this.modulus,
    required this.publicExponent,
    required this.privateExponent,
  });

  int get bitLength => modulus.bitLength;
  int get byteLength => (modulus.bitLength + 7) >> 3;
}

/// Pure-Dart RS256 JWT Signer for Enable Banking API authentication.
///
/// Enable Banking requires:
/// - Header: `{"typ": "JWT", "alg": "RS256", "kid": "<app_id>"}`
/// - Payload: `{"iss": "enablebanking.com", "aud": "api.enablebanking.com", "iat": <int>, "exp": <int>}`
/// - Max TTL: 86400 seconds (24 hours).
class EnableBankingJwtSigner {
  /// DER DigestInfo prefix for SHA-256 (RFC 8017 Section 9.2)
  static const List<int> _sha256DigestInfoPrefix = [
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
    0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
    0x00, 0x04, 0x20,
  ];

  /// Creates and signs an Enable Banking RS256 JWT.
  static String createJwt({
    required String appId,
    required String privateKeyPem,
    DateTime? issuedAt,
    int ttlSeconds = 3600,
  }) {
    if (appId.trim().isEmpty) {
      throw ArgumentError('Application ID (kid) ne peut pas être vide.');
    }
    if (ttlSeconds <= 0 || ttlSeconds > 86400) {
      throw ArgumentError(
        'TTL doit être compris entre 1 et 86400 secondes (24h max).',
      );
    }

    final rsaKey = parsePrivateKeyFromPem(privateKeyPem);
    final iat =
        ((issuedAt ?? DateTime.now()).millisecondsSinceEpoch / 1000).floor();
    final exp = iat + ttlSeconds;

    final header = <String, dynamic>{
      'typ': 'JWT',
      'alg': 'RS256',
      'kid': appId.trim(),
    };

    final payload = <String, dynamic>{
      'iss': 'enablebanking.com',
      'aud': 'api.enablebanking.com',
      'iat': iat,
      'exp': exp,
    };

    final encodedHeader = _base64UrlNoPad(utf8.encode(jsonEncode(header)));
    final encodedPayload = _base64UrlNoPad(utf8.encode(jsonEncode(payload)));
    final signingInput = '$encodedHeader.$encodedPayload';

    final signatureBytes = signRs256(
      Uint8List.fromList(utf8.encode(signingInput)),
      rsaKey,
    );
    final encodedSignature = _base64UrlNoPad(signatureBytes);

    return '$signingInput.$encodedSignature';
  }

  /// Signs [message] using RSA PKCS#1 v1.5 with SHA-256 (RS256).
  static Uint8List signRs256(
    Uint8List message,
    RsaPrivateKeyParameters privateKey,
  ) {
    final k = privateKey.byteLength;
    final digest = sha256.convert(message).bytes;
    final tLength = _sha256DigestInfoPrefix.length + digest.length; // 51 bytes

    if (k < tLength + 11) {
      throw ArgumentError(
        'Clé RSA trop courte (${privateKey.bitLength} bits) pour RS256.',
      );
    }

    final em = Uint8List(k);
    em[0] = 0x00;
    em[1] = 0x01;
    final psLength = k - tLength - 3;
    for (var i = 0; i < psLength; i++) {
      em[2 + i] = 0xFF;
    }
    em[2 + psLength] = 0x00;
    final tOffset = 3 + psLength;
    em.setRange(tOffset, tOffset + _sha256DigestInfoPrefix.length,
        _sha256DigestInfoPrefix);
    em.setRange(
      tOffset + _sha256DigestInfoPrefix.length,
      k,
      digest,
    );

    final m = _bytesToBigInt(em);
    final s = m.modPow(privateKey.privateExponent, privateKey.modulus);
    return _bigIntToBytes(s, k);
  }

  /// Verifies an RS256 signature using the public key components `(modulus, publicExponent)`.
  static bool verifyRs256(
    Uint8List message,
    Uint8List signature,
    RsaPrivateKeyParameters key,
  ) {
    final k = key.byteLength;
    if (signature.length != k) return false;

    final s = _bytesToBigInt(signature);
    if (s >= key.modulus) return false;

    final m = s.modPow(key.publicExponent, key.modulus);
    final em = _bigIntToBytes(m, k);

    final digest = sha256.convert(message).bytes;
    final tLength = _sha256DigestInfoPrefix.length + digest.length;
    if (k < tLength + 11) return false;

    if (em[0] != 0x00 || em[1] != 0x01) return false;
    final psLength = k - tLength - 3;
    for (var i = 0; i < psLength; i++) {
      if (em[2 + i] != 0xFF) return false;
    }
    if (em[2 + psLength] != 0x00) return false;

    final tOffset = 3 + psLength;
    for (var i = 0; i < _sha256DigestInfoPrefix.length; i++) {
      if (em[tOffset + i] != _sha256DigestInfoPrefix[i]) return false;
    }
    final digestOffset = tOffset + _sha256DigestInfoPrefix.length;
    for (var i = 0; i < digest.length; i++) {
      if (em[digestOffset + i] != digest[i]) return false;
    }
    return true;
  }

  /// Parses either a PKCS#8 (`BEGIN PRIVATE KEY`) or PKCS#1 (`BEGIN RSA PRIVATE KEY`) PEM string.
  static RsaPrivateKeyParameters parsePrivateKeyFromPem(String pem) {
    final lines = pem
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('-----'))
        .join('');

    if (lines.isEmpty) {
      throw const FormatException('Clé privée PEM vide ou invalide.');
    }

    final Uint8List derBytes;
    try {
      derBytes = base64Decode(lines);
    } catch (e) {
      throw FormatException('Contenu Base64 de la clé PEM invalide: $e');
    }

    return _parseDerPrivateKey(derBytes);
  }

  static RsaPrivateKeyParameters _parseDerPrivateKey(Uint8List der) {
    final reader = _Asn1Reader(der);
    final topSeq = reader.readSequence();

    // Read version INTEGER
    topSeq.readInteger();

    if (topSeq.peekTag() == 0x30) {
      // PKCS#8 PrivateKeyInfo:
      // SEQUENCE { version INTEGER, privateKeyAlgorithm SEQUENCE, privateKey OCTET STRING }
      topSeq.readSequence(); // Skip algorithm identifier
      final pkcs1Bytes = topSeq.readOctetString();
      return _parsePkcs1RsaPrivateKey(pkcs1Bytes);
    } else {
      // Already PKCS#1 RSAPrivateKey:
      // SEQUENCE { version, modulus, publicExponent, privateExponent, ... }
      final modulus = topSeq.readInteger();
      final publicExponent = topSeq.readInteger();
      final privateExponent = topSeq.readInteger();
      return RsaPrivateKeyParameters(
        modulus: modulus,
        publicExponent: publicExponent,
        privateExponent: privateExponent,
      );
    }
  }

  static RsaPrivateKeyParameters _parsePkcs1RsaPrivateKey(Uint8List bytes) {
    final reader = _Asn1Reader(bytes);
    final seq = reader.readSequence();
    seq.readInteger(); // version
    final modulus = seq.readInteger();
    final publicExponent = seq.readInteger();
    final privateExponent = seq.readInteger();
    return RsaPrivateKeyParameters(
      modulus: modulus,
      publicExponent: publicExponent,
      privateExponent: privateExponent,
    );
  }

  static String _base64UrlNoPad(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  static Uint8List _bigIntToBytes(BigInt value, int length) {
    final result = Uint8List(length);
    var temp = value;
    final mask = BigInt.from(0xFF);
    for (var i = length - 1; i >= 0; i--) {
      result[i] = (temp & mask).toInt();
      temp = temp >> 8;
    }
    return result;
  }
}

class _Asn1Reader {
  final Uint8List _bytes;
  int _offset = 0;

  _Asn1Reader(this._bytes);

  int peekTag() {
    if (_offset >= _bytes.length) {
      throw const FormatException('Fin inattendue de la structure ASN.1.');
    }
    return _bytes[_offset];
  }

  _Asn1Reader readSequence() {
    final tag = _readByte();
    if (tag != 0x30) {
      throw FormatException(
        'Tag ASN.1 SEQUENCE (0x30) attendu, reçu 0x${tag.toRadixString(16)}.',
      );
    }
    final length = _readLength();
    final subBytes = _readBytes(length);
    return _Asn1Reader(subBytes);
  }

  Uint8List readOctetString() {
    final tag = _readByte();
    if (tag != 0x04) {
      throw FormatException(
        'Tag ASN.1 OCTET STRING (0x04) attendu, reçu 0x${tag.toRadixString(16)}.',
      );
    }
    final length = _readLength();
    return _readBytes(length);
  }

  BigInt readInteger() {
    final tag = _readByte();
    if (tag != 0x02) {
      throw FormatException(
        'Tag ASN.1 INTEGER (0x02) attendu, reçu 0x${tag.toRadixString(16)}.',
      );
    }
    final length = _readLength();
    final bytes = _readBytes(length);
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  int _readByte() {
    if (_offset >= _bytes.length) {
      throw const FormatException('Fin inattendue du flux ASN.1.');
    }
    return _bytes[_offset++];
  }

  int _readLength() {
    final first = _readByte();
    if ((first & 0x80) == 0) {
      return first;
    }
    final numBytes = first & 0x7F;
    if (numBytes == 0 || numBytes > 4) {
      throw FormatException('Longueur ASN.1 non supportée: $numBytes octets.');
    }
    var length = 0;
    for (var i = 0; i < numBytes; i++) {
      length = (length << 8) | _readByte();
    }
    return length;
  }

  Uint8List _readBytes(int length) {
    if (_offset + length > _bytes.length) {
      throw const FormatException('Données ASN.1 tronquées.');
    }
    final slice = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return slice;
  }
}

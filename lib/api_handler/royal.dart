import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CurfoxService {
  static const String _defaultApiBase =
      'https://v1.api.curfox.com/api/public/merchant';

  static String get apiBase {
    final configuredBase = dotenv.env['CURFOX_BASE_URL']?.trim();
    if (configuredBase == null || configuredBase.isEmpty) {
      return _defaultApiBase;
    }

    final uri = Uri.tryParse(configuredBase);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw StateError('CURFOX_BASE_URL must be a valid HTTPS URL.');
    }

    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isEmpty) {
      path = '/api/public/merchant';
    } else if (path.endsWith('/api/public')) {
      path = '$path/merchant';
    }
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  static String get tenantId {
    final tenant = dotenv.env['CURFOX_TENANT_ID']?.trim();
    if (tenant == null || tenant.isEmpty) {
      throw StateError('CURFOX_TENANT_ID is missing from .env.');
    }
    return tenant;
  }

  static String get authToken {
    final token = dotenv.env['CURFOX_AUTH_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw StateError('CURFOX_AUTH_TOKEN is missing from .env.');
    }
    return _withoutBearerPrefix(token);
  }

  static Map<String, String> headers({String? token, String? tenant}) {
    final normalizedToken = _withoutBearerPrefix(token ?? authToken);
    final normalizedTenant = (tenant ?? tenantId).trim();
    if (normalizedToken.isEmpty || normalizedTenant.isEmpty) {
      throw StateError('Curfox authentication configuration is incomplete.');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-tenant': normalizedTenant,
      'Authorization': 'Bearer $normalizedToken',
    };
  }

  static String _withoutBearerPrefix(String token) {
    return token.trim().replaceFirst(
      RegExp(r'^Bearer\s+', caseSensitive: false),
      '',
    );
  }

  Future<String?> getCurrentStatus(String waybill) async {
    final trackingUri = Uri.parse(
      '${apiBase.replaceFirst('/merchant', '')}/order/tracking-info',
    );
    final response = await http.post(
      trackingUri,
      headers: headers(),
      body: jsonEncode({'waybill_number': waybill}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Curfox tracking failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map ||
        decoded['data'] is! Map ||
        (decoded['data'] as Map)['timeline'] is! List) {
      throw const FormatException('Curfox returned an invalid tracking response.');
    }
    final timeline = (decoded['data'] as Map)['timeline'] as List;
    if (timeline.isEmpty ||
        timeline.first is! Map ||
        (timeline.first as Map)['status'] is! Map) {
      return null;
    }
    return ((timeline.first as Map)['status'] as Map)['name']?.toString();
  }
}

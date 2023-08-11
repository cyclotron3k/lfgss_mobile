import 'api_client.dart';

class DummyClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> getJson(Uri url, {int ttl = 0}) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> post(Uri url, {int ttl = 0}) async {
    return {};
  }
}

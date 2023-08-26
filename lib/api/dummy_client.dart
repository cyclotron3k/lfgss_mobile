import 'api_client.dart';

typedef Json = Map<String, dynamic>;

class DummyClient implements ApiClient {
  @override
  Future<Json> getJson(Uri url, {int ttl = 0}) async {
    return {};
  }

  @override
  Future<Json> postJson(Uri url, Json body) async {
    return {};
  }

  Future<Json> post(Uri url) async {
    return {};
  }
}

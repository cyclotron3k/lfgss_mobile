typedef Json = Map<String, dynamic>;

abstract class ApiClient {
  Future<Json> getJson(Uri url, {int ttl = 0});
  Future<Json> postJson(Uri url, Json body);
}

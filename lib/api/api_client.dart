abstract class ApiClient {
  Future<Map<String, dynamic>> getJson(Uri url, {int ttl = 0});
  Future<Map<String, dynamic>> post(Uri url, {int ttl = 0});
}

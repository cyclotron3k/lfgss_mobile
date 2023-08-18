import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:developer' as developer;
import '../constants.dart';
import 'api_client.dart';

typedef Json = Map<String, dynamic>;

class _ExpiringResponse {
  int expiresAt;
  Future<Json> response;

  _ExpiringResponse({
    required this.expiresAt,
    required this.response,
  });

  bool get expired {
    if (expiresAt == 0) return false;
    return expiresAt < DateTime.now().millisecondsSinceEpoch;
  }
}

class MicrocosmClient implements ApiClient {
  static final MicrocosmClient _singleton = MicrocosmClient._internal();

  factory MicrocosmClient() {
    return _singleton;
  }

  MicrocosmClient._internal();

  final Map<Uri, _ExpiringResponse> _inFlight = {};

  Future<Response> get(Uri url) async {
    return http.get(
      url,
      headers: {
        'Authorization': BEARER_TOKEN,
      },
    );
  }

  @override
  Future<Json> getJson(Uri url, {int ttl = 60}) async {
    if (_inFlight.containsKey(url)) {
      assert(_inFlight.containsKey(url));
      if (_inFlight[url]!.expired) {
        developer.log("Refreshing expired page: $url");
        _inFlight.remove(url);
      } else {
        developer.log("Awaiting page: $url");
      }
    } else {
      developer.log("Requesting page: $url");
    }

    int expiresAt = DateTime.now().millisecondsSinceEpoch + ttl * 1000;

    _inFlight[url] ??= _ExpiringResponse(
      expiresAt: expiresAt,
      response: get(url).then((response) {
        developer.log("Retrieved page: $url");
        String page = const Utf8Decoder().convert(response.body.codeUnits);
        Json data = json.decode(page);
        if (data["status"] != 200) {
          developer.log("Failed to retrieve resource from: $url");
          developer.log("Error: ${data["error"]}");
          throw "Couldn't retrieve resource: $url";
        }
        return data["data"];
      }),
    );

    return await _inFlight[url]!.response;
  }

  @override
  Future<Json> post(Uri url) async {
    return {};
  }

  // Uri getUrl({Json params = const {}}) {
  //   Map<String, String> stringy = {};

  //   for (var item in params.keys) {
  //     stringy[item] = params[item].toString();
  //   }

  //   return Uri.https(
  //     HOST,
  //     "/api/v1$path/$id",
  //     stringy,
  //   );
  // }
}

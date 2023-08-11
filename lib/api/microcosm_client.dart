import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:developer' as developer;
import '../constants.dart';
import 'api_client.dart';

typedef Json = Map<String, dynamic>;

class MicrocosmClient implements ApiClient {
  static final MicrocosmClient _singleton = MicrocosmClient._internal();

  factory MicrocosmClient() {
    return _singleton;
  }

  MicrocosmClient._internal();

  Map<Uri, Future<Json>> inFlight = {};

  Future<Response> get(Uri url) async {
    return http.get(
      url,
      headers: {
        'Authorization': BEARER_TOKEN,
      },
    );
  }

  @override
  Future<Json> getJson(Uri url, {int ttl = 0}) async {
    if (inFlight.containsKey(url)) {
      developer.log("Awaiting page: $url");
    } else {
      developer.log("Requesting page: $url");
    }

    inFlight[url] ??= get(url).then((response) {
      developer.log("Retrieved page: $url");
      String page = const Utf8Decoder().convert(response.body.codeUnits);
      Json data = json.decode(page);
      if (data["status"] != 200) {
        developer.log("Failed to retrieve resource from: $url");
        developer.log("Error: ${data["error"]}");
        throw "Couldn't retrieve resource: $url";
      }
      return data["data"];
    });

    return await inFlight[url]!;
  }

  @override
  Future<Json> post(Uri url, {int ttl = 0}) async {
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

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

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

class MicrocosmClient {
  static const String userAgent = "LFGSSMobile/0.0.1 (android;cyclotron3k)";
  static final MicrocosmClient _singleton = MicrocosmClient._internal();
  String? accessToken;

  factory MicrocosmClient() {
    return _singleton;
  }

  MicrocosmClient._internal();

  final Map<Uri, _ExpiringResponse> _inFlight = {};

  bool get loggedIn {
    return accessToken != null;
  }

  Future<void> updateAccessToken() async {
    // developer.log("Getting access token...");

    final sharedPreference = await SharedPreferences.getInstance();
    accessToken = sharedPreference.getString("accessToken");
    developer.log("Retrieved access token: $accessToken");
  }

  Future<Response> get(Uri url) async {
    return http.get(
      url,
      headers: {
        'User-Agent': userAgent,
        if (accessToken != null) 'Authorization': "Bearer $accessToken",
      },
    );
  }

  Future<void> logout() async {
    // TODO: looks like logout isn't implemented on the backend?

    if (accessToken == null) return;

    final sharedPreference = await SharedPreferences.getInstance();
    await sharedPreference.remove("accessToken");
    accessToken = null;

    // var uri = Uri.https(
    //   HOST,
    //   "/api/v1/auth/$accessToken",
    // );

    // await http.delete(
    //   uri,
    //   headers: {
    //     'Authorization': "Bearer $accessToken",
    //   },
    // );
  }

  Future<Json> getJson(
    Uri url, {
    int ttl = 60,
    bool ignoreCache = false,
  }) async {
    if (_inFlight.containsKey(url)) {
      assert(_inFlight.containsKey(url));
      if (ignoreCache || _inFlight[url]!.expired) {
        developer.log("Refreshing expired page: $url");
        _inFlight.remove(url);
      } else {
        // developer.log("Awaiting page: $url");
      }
    } else {
      // developer.log("Requesting page: $url");
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

  Future<Json> postJson(
    Uri url,
    Json body, {
    bool followRedirects = true,
  }) async {
    developer.log("Posting to: $url");
    var response = await post(url, body);

    if (response.statusCode == 302) {
      if (followRedirects) {
        Uri redirect = Uri.parse(response.headers['location']!);
        if (!redirect.isAbsolute) {
          redirect = redirect.replace(
            scheme: "https",
            host: HOST,
          );
        }
        developer.log("Completed post. Redirecting to: $redirect");
        return getJson(redirect, ignoreCache: true);
      } else {
        return {};
      }
    }

    String page = const Utf8Decoder().convert(response.body.codeUnits);

    Json data = json.decode(page);

    if (data["status"] != 200) {
      developer.log("Failed to retrieve resource from: $url");
      developer.log("Error: ${data["error"]}");
      throw "Couldn't retrieve resource: $url";
    }

    return data["data"];
  }

  Future<Response> post(Uri url, Json body) async {
    String jsonBody = jsonEncode(body);
    return http.post(
      url,
      headers: <String, String>{
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      body: jsonBody,
    );
  }

  Future<dynamic> upload(Uri uri, List<File> files) async {
    developer.log("Uploading ${files.length} file(s)");

    var request = http.MultipartRequest('POST', uri);
    request.headers['User-Agent'] = userAgent;
    request.headers['Authorization'] = "Bearer $accessToken";

    for (File file in files) {
      developer.log("Adding ${file.uri.pathSegments.last} to the payload");
      request.files.add(await http.MultipartFile.fromPath(
        'file', file.path,
        filename: file.uri.pathSegments.last,
        // contentType: MediaType('application', 'x-tar'),
      ));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      developer.log("Upload success");
      List<int> responseBytes = await response.stream.toBytes();
      String page = utf8.decode(responseBytes);
      Json data = json.decode(page);
      return data['data'];
    } else {
      developer.log("Upload failed");
      throw "Error from API Upload: ${response.statusCode}";
    }
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

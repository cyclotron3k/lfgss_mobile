import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'relaxed_jpeg_decoder.dart';

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
  static const String userAgent = "LFGSSMobile/1.0.3 (android;cyclotron3k)";
  static final MicrocosmClient _singleton = MicrocosmClient._internal();
  String? accessToken;

  factory MicrocosmClient() {
    return _singleton;
  }

  MicrocosmClient._internal();

  final Map<Uri, _ExpiringResponse> _inFlight = {};

  void clearCache() {
    _inFlight.removeWhere((key, value) => true);
  }

  bool get loggedIn {
    return accessToken != null;
  }

  Future<void> updateAccessToken() async {
    final sharedPreference = await SharedPreferences.getInstance();
    final newAccessToken = sharedPreference.getString("accessToken");
    if (accessToken != newAccessToken) {
      clearCache();
      accessToken = newAccessToken;
    }
  }

  Future<http.Response> get(Uri url) async {
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
        log("Refreshing expired page: $url");
        _inFlight.remove(url);
      } else {
        // log("Awaiting page: $url");
      }
    } else {
      // log("Requesting page: $url");
    }

    int expiresAt = DateTime.now().millisecondsSinceEpoch + ttl * 1000;

    _inFlight[url] ??= _ExpiringResponse(
      expiresAt: expiresAt,
      response: get(url).then((response) {
        log("Retrieved page: $url");
        String page = const Utf8Decoder().convert(response.body.codeUnits);
        Json data = json.decode(page);
        if (data["status"] != 200) {
          log("Failed to retrieve resource from: $url");
          log("Error: ${data["error"]}");
          throw "Couldn't retrieve resource: $url";
        }
        return data["data"];
      }),
    );

    return await _inFlight[url]!.response;
  }

  Future<Json> postJson(
    Uri url,
    Object body, {
    bool followRedirects = true,
  }) async {
    log("Posting to: $url");
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
        log("Completed post. Redirecting to: $redirect");
        return getJson(redirect, ignoreCache: true);
      } else {
        return {};
      }
    }

    String page = const Utf8Decoder().convert(response.body.codeUnits);

    Json data = json.decode(page);

    if (data["status"] != 200) {
      log("Failed to POST to: $url");
      log("Error: ${data["error"]}");
      throw "Couldn't POST to: $url";
    }

    return data["data"];
  }

  Future<http.Response> post(Uri url, Object body) async {
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

  Future<Json> putJson(
    Uri url,
    Object body, {
    bool followRedirects = true,
  }) async {
    log("PUTting to: $url");
    var response = await put(url, body);

    if (response.statusCode == 302) {
      if (followRedirects) {
        Uri redirect = Uri.parse(response.headers['location']!);
        if (!redirect.isAbsolute) {
          redirect = redirect.replace(
            scheme: "https",
            host: HOST,
          );
        }
        log("Completed post. Redirecting to: $redirect");
        return getJson(redirect, ignoreCache: true);
      } else {
        return {};
      }
    }

    String page = const Utf8Decoder().convert(response.body.codeUnits);

    Json data = json.decode(page);

    if (data["status"] != 200) {
      log("Failed to PUT to: $url");
      log("Error: ${data["error"]}");
      throw "Couldn't PUt to: $url";
    }

    return data["data"];
  }

  Future<http.Response> put(Uri url, Object body) async {
    String jsonBody = jsonEncode(body);
    return http.put(
      url,
      headers: <String, String>{
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      body: jsonBody,
    );
  }

  int _scaleImage(File file) {
    log("Getting image size of ${file.path}");
    ImageSizeGetter.registerDecoder(const RelaxedJpegDecoder());
    final size = ImageSizeGetter.getSize(FileInput(file));

    log("Image width: ${size.width}, height: ${size.height}");
    return _scale(size.width, size.height);
  }

  int _scale(int width, int height) {
    log("width: $width, height: $height");
    var minDimension = math.min(width, height);
    var pixels = width * height;
    var targetPixels = 3100000;
    double scaling = math.sqrt(pixels / targetPixels);
    scaling = (scaling * 2.0).roundToDouble() / 2.0;
    if (scaling <= 1.0) {
      return minDimension;
    }
    var minLength = minDimension / scaling;
    var nmp = (width / scaling) * (height / scaling);
    log("Downscaling from $pixels to $nmp");
    return minLength.round();
  }

  Future<dynamic> uploadImages(Uri uri, List<File> images) async {
    log("Uploading ${images.length} file(s)");

    var request = http.MultipartRequest('POST', uri);
    request.headers['User-Agent'] = userAgent;
    request.headers['Authorization'] = "Bearer $accessToken";

    var sharedPreference = await SharedPreferences.getInstance();
    bool shrink = sharedPreference.getBool("shrinkLargeImages") ?? true;
    bool removeExif = sharedPreference.getBool("sanitizeImages") ?? true;

    for (File file in images) {
      log("Adding ${file.uri.pathSegments.last} to the payload.");
      if (shrink ^ removeExif) {
        int scaleDim = _scaleImage(file);
        log("maxDim is $scaleDim");
        var bytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: scaleDim,
          minHeight: scaleDim,
          quality: 80,
          keepExif: !removeExif,
        );
        var f = http.MultipartFile.fromBytes(
          'file',
          bytes!,
          filename: file.uri.pathSegments.last,
        );
        request.files.add(f);
      } else {
        var f = await http.MultipartFile.fromPath(
          'file', file.path,
          filename: file.uri.pathSegments.last,
          // contentType: MediaType('application', 'x-tar'),
        );
        request.files.add(f);
      }
    }

    log("Sending attachments");
    var response = await request.send();

    if (response.statusCode == 200) {
      log("Upload success");
      List<int> responseBytes = await response.stream.toBytes();
      String page = utf8.decode(responseBytes);
      Json data = json.decode(page);
      return data['data'];
    } else {
      log("Upload failed");
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

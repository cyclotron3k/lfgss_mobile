import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:quiver/collection.dart' show LruMap;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import '../constants.dart';
import 'relaxed_jpeg_decoder.dart';

typedef Json = Map<String, dynamic>;
typedef UploadProgressCallback = void Function(int sentBytes, int totalBytes);

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

class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final UploadProgressCallback? onProgress;

  @override
  http.ByteStream finalize() {
    final stream = super.finalize();

    if (onProgress == null) {
      return stream;
    }

    final totalBytes = contentLength;
    var sentBytes = 0;

    return http.ByteStream(
      stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (chunk, sink) {
            sentBytes += chunk.length;
            onProgress!(sentBytes, totalBytes);
            sink.add(chunk);
          },
        ),
      ),
    );
  }
}

class MicrocosmClient {
  static const String userAgent = USER_AGENT;
  static final MicrocosmClient _singleton = MicrocosmClient._internal();
  String? accessToken;

  factory MicrocosmClient() {
    return _singleton;
  }

  MicrocosmClient._internal();

  final _inFlight = LruMap<Uri, _ExpiringResponse>(maximumSize: 4096);

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

  Future<void> logout() async {
    if (accessToken == null) return;

    await http.delete(
      Uri.https(
        API_HOST,
        "/api/v1/auth/$accessToken",
      ),
      headers: {
        'Authorization': "Bearer $accessToken",
      },
    ).then(
      (value) => log("Deleted access token: ${value.statusCode}"),
    );

    final sharedPreference = await SharedPreferences.getInstance();
    await sharedPreference.remove("accessToken");
    accessToken = null;

    clearCache();

    final cookieManager = WebviewCookieManager();
    cookieManager.clearCookies();
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

    final future = get(url).then((response) {
      log("Retrieved page: $url");
      String page = response
          .body; // const Utf8Decoder().convert(response.body.codeUnits);
      Json data = json.decode(page);
      if (data["status"] != 200) {
        log("Failed to retrieve resource from: $url");
        log("Error: ${data["error"]}");
        throw "Couldn't retrieve resource: $url";
      }
      return data["data"] as Json;
    }, onError: (error) => log("Error: $error"));

    future.catchError((error) {
      _inFlight.remove(url);
      throw error;
    });

    _inFlight[url] ??= _ExpiringResponse(
      expiresAt: expiresAt,
      response: future,
    );

    return await _inFlight[url]!.response;
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
            host: API_HOST,
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

  Future<http.Response> put(Uri url, Object body) async {
    String jsonBody = jsonEncode(body);
    log("PUTting $jsonBody");
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

  Future<Json?> putJson(
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
            host: API_HOST,
          );
        }
        log("Completed PUT. Redirecting to: $redirect");
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
      throw "Couldn't PUT to: $url";
    }

    return data["data"];
  }

  Future<http.Response> delete(Uri url, [Object? body]) async {
    final headers = <String, String>{
      'User-Agent': userAgent,
      if (accessToken != null) 'Authorization': "Bearer $accessToken",
    };

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    return http.delete(
      url,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<Json?> deleteJson(
    Uri url, {
    Object? body,
    bool followRedirects = true,
  }) async {
    log("DELETEing: $url");
    final response = await delete(url, body);

    if (response.statusCode == 302) {
      if (followRedirects) {
        Uri redirect = Uri.parse(response.headers['location']!);
        if (!redirect.isAbsolute) {
          redirect = redirect.replace(
            scheme: "https",
            host: API_HOST,
          );
        }
        log("Completed DELETE. Redirecting to: $redirect");
        return getJson(redirect, ignoreCache: true);
      } else {
        return {};
      }
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      log("Failed to DELETE: $url");
      throw "Couldn't DELETE: $url";
    }

    final String page = const Utf8Decoder().convert(response.body.codeUnits);
    final Json data = json.decode(page);

    if (data["status"] != 200) {
      log("Failed to DELETE: $url");
      log("Error: ${data["error"]}");
      throw "Couldn't DELETE: $url";
    }

    return data["data"];
  }

  int _scaleImage(File file) {
    log("Getting image size of ${file.path}");
    ImageSizeGetter.registerDecoder(const RelaxedJpegDecoder());
    final size = ImageSizeGetter.getSizeResult(FileInput(file)).size;

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

  Future<dynamic> uploadImages(
    Uri uri,
    List<File> images, {
    UploadProgressCallback? onProgress,
  }) async {
    log("Uploading ${images.length} file(s)");

    var request = _ProgressMultipartRequest(
      'POST',
      uri,
      onProgress: onProgress,
    );
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
}

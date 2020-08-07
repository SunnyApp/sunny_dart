class RequestBuilder {
  String path;
  HttpMethod method;
  String basePath;

  final Map<String, Object> queryParams = {};
  final Map<String, Object> pathParams = {};
  Object body;
  final Map<String, String> headerParams = {};
  final Map<String, String> formParams = {};
  String contentType;

  String get requestUrl {
    var ps = queryParams.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}');
    String queryString = ps.isNotEmpty ? '?' + ps.join('&') : '';

    var requestPath = path;
    pathParams.forEach((key, value) =>
        requestPath = requestPath.replaceAll("{$key}", "$value"));
    String url = basePath + requestPath + queryString;
    return url;
  }

//  BaseRequest build({bool streamRequest = false}) {
//    String method;
//    switch (this.method) {
//      case HttpMethod.GET:
//        method = "GET";
//        break;
//      case HttpMethod.POST:
//        method = "POST";
//        break;
//      case HttpMethod.PUT:
//        method = "PUT";
//        break;
//      case HttpMethod.PATCH:
//        method = "PATCH";
//        break;
//      case HttpMethod.DELETE:
//        method = "DELETE";
//        break;
//      default:
//        method = "GET";
//    }
//
//    if (body is MultipartRequest) {
//      final requestBody = this.body as MultipartRequest;
//      var mpRequest = MultipartRequest(requestBody.method, Uri.parse(requestUrl));
//      mpRequest.fields.addAll(requestBody.fields);
//      mpRequest.files.addAll(requestBody.files);
//      mpRequest.headers.addAll(requestBody.headers);
//      mpRequest.headers.addAll(headerParams);
//      return mpRequest;
//    }
//
//    BaseRequest request;
//    if (streamRequest == true) {
//      StreamedRequest req = StreamedRequest(method, Uri.parse(this.requestUrl));
//      assert(this.body is Uint8List);
//      final body = this.body as Uint8List;
//
//      req.contentLength = body.length;
//      req.send();
//    } else {
//      Request req = Request(method, Uri.parse(this.requestUrl));
//      if (contentType == "application/x-www-form-urlencoded") {
//        req.bodyFields = formParams;
//      } else {
//        final data = ApiClient.serialize(body);
//        if (data is Uint8List) {
//          req.bodyBytes = data;
//        } else {
//          req.body = data as String;
//        }
//      }
//
//      req.encoding = Encoding.getByName("UTF-8");
//      request = req;
//    }
//
//    request.headers.addAll(headerParams);
//    return request;
//  }
}

enum HttpMethod { GET, POST, PUT, PATCH, DELETE }

//extension HttpMethodExtension on HttpMethod {
//  fb.HttpMethod toFirebaseHttpMethod() {
//    if (this == null) return null;
//    switch (this) {
//      case HttpMethod.GET:
//        return fb.HttpMethod.Get;
//      case HttpMethod.POST:
//        return fb.HttpMethod.Post;
//      case HttpMethod.PUT:
//        return fb.HttpMethod.Put;
//      case HttpMethod.PATCH:
//        return fb.HttpMethod.Patch;
//      case HttpMethod.DELETE:
//        return fb.HttpMethod.Delete;
//      default:
//        return fb.HttpMethod.Get;
//    }
//  }
//}

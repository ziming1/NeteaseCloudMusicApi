import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:netease_music_api/src/answer.dart';
import 'src/module.dart';

typedef DebugPrinter = void Function(String message);

typedef QueryParameterDecryptor = Map<String, String> Function(
  Map<String, String> queryParameter,
);

DebugPrinter debugPrint = (msg) {
  print(msg);
};

Future<HttpServer> startServer({
  address = "localhost",
  int port = 3000,
  QueryParameterDecryptor decryptor,
}) {
  return HttpServer.bind(address, port, shared: true).then((server) {
    debugPrint("start listen at: http://$address:$port");
    server.listen((request) {
      _handleRequest(request, decryptor);
    });
    return server;
  });
}

void _handleRequest(HttpRequest request, QueryParameterDecryptor decryptor) async {
  final handle = handles[request.uri.path];

  Answer answer;
  if (handle != null) {
    try {
      var param = request.uri.queryParameters;
      if (decryptor != null) {
        param = decryptor(param);
      }
      answer = await handle(param, request.cookies);
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      answer = Answer();
    }
  }
  answer ??= Answer();
  request.response.statusCode = answer.status;
  request.response.cookies.addAll(answer.cookie);
  request.response.write(json.encode(answer.body));
  request.response.close();

  debugPrint("request[${answer.status}] : ${request.uri}");
}

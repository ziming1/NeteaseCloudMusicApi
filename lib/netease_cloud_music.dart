import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:netease_music_api/src/answer.dart';

import 'src/module.dart';

typedef DebugPrinter = void Function(String message);

DebugPrinter debugPrint = (msg) {
  print(msg);
};

Future<HttpServer> startServer({address = "localhost", int port = 3000}) {
  return HttpServer.bind(address, port).then((server) {
    debugPrint("start listen at: http://$address:$port");
    server.listen((request) {
      debugPrint("request : ${request.uri}");
      _handleRequest(request);
    });
  });
}

void _handleRequest(HttpRequest request) async {
  final handle = handles[request.uri.path];

  Answer answer;
  if (handle != null) {
    try {
      answer = await handle(request.uri.queryParameters, request.cookies);
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
}

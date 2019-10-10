import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:netease_music_api/netease_cloud_music.dart';
import 'package:netease_music_api/src/answer.dart';

main(List<String> arguments) {
  _startServer(port: 3001);
}

Future<HttpServer> _startServer({address = "localhost", int port = 3000}) {
  return HttpServer.bind(address, port, shared: true).then((server) {
    debugPrint("start listen at: http://$address:$port");
    server.listen((request) {
      _handleRequest(request);
    });
    return server;
  });
}

void _handleRequest(HttpRequest request) async {
  final answer = await cloudMusicApi(request.uri.path, parameter: request.uri.queryParameters, cookie: request.cookies)
      .catchError((e, s) async {
    debugPrint(e.toString());
    debugPrint(s.toString());
    return const Answer();
  });

  request.response.statusCode = answer.status;
  request.response.cookies.addAll(answer.cookie);
  request.response.write(json.encode(answer.body));
  request.response.close();

  debugPrint("request[${answer.status}] : ${request.uri}");
}

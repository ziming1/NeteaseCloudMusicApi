import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:netease_music_api/netease_cloud_music.dart';
import 'package:netease_music_api/src/answer.dart';

import 'crypto.dart';

enum Crypto { linuxapi, weapi, eapi }

String _chooseUserAgent({String ua}) {
  const userAgentList = [
    'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1',
    'Mozilla/5.0 (Linux; Android 5.0; SM-G900P Build/LRX21T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 5.1.1; Nexus 6 Build/LYZ28E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Mobile Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_2 like Mac OS X) AppleWebKit/603.2.4 (KHTML, like Gecko) Mobile/14F89;GameHelper',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, like Gecko) Version/10.0 Mobile/14A300 Safari/602.1',
    'Mozilla/5.0 (iPad; CPU OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, like Gecko) Version/10.0 Mobile/14A300 Safari/602.1',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:46.0) Gecko/20100101 Firefox/46.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:46.0) Gecko/20100101 Firefox/46.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/13.10586'
  ];

  var r = Random();
  int index;
  if (ua == 'mobile') {
    index = (r.nextDouble() * 7).floor();
  } else if (ua == "pc") {
    index = (r.nextDouble() * 5).floor() + 8;
  } else {
    index = (r.nextDouble() * (userAgentList.length - 1)).floor();
  }
  return userAgentList[index];
}

Future<Answer> request(
  String method,
  String url,
  Map data, {
  List<Cookie> cookies = const [],
  String ua,
  Crypto crypto = Crypto.weapi,
}) async {
  final headers = {'User-Agent': _chooseUserAgent(ua: ua)};
  if (method.toUpperCase() == 'POST')
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
  if (url.contains('music.163.com'))
    headers['Referer'] = 'https://music.163.com';

  headers['Cookie'] = cookies.join("; ");
  if (crypto == Crypto.weapi) {
    var csrfToken =
        cookies.firstWhere((c) => c.name == "__csrf", orElse: () => null);
    data["csrf_token"] = csrfToken?.value ?? "";
    data = weApi(data);
    url = url.replaceAll(RegExp(r"\w*api"), 'weapi');
  } else if (crypto == Crypto.linuxapi) {
    data = linuxApi({
      "params": data,
      "url": url.replaceAll(RegExp(r"\w*api"), 'api'),
      "method": method,
    });
    headers['User-Agent'] =
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36';
    url = 'https://music.163.com/api/linux/forward';
  } else if (crypto == Crypto.eapi) {
    final cookie = {};
    var csrfToken;
    final header = {
      //系统版本
      "osver": cookie['osver'],
      //encrypt.base64.encode(imei + '\t02:00:00:00:00:00\t5106025eb79a5247\t70ffbaac7')
      "deviceId": cookie['deviceId'],
      // app版本
      "appver": cookie['appver'] ?? "6.1.1",
      //版本号
      "versioncode": cookie['versioncode'] ?? "140",
      //设备model
      "mobilename": cookie['mobilename'],
      "buildver": cookie['buildver'] ??
          (DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)),
      //设备分辨率
      "resolution": cookie['resolution'] ?? "1920x1080",
      "__csrf": csrfToken,
      "os": cookie['os'] ?? 'android',
      "channel": cookie['channel'],
      "requestId":
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000).toString().padLeft(4, '0')}'
    };
    if (cookie['MUSIC_U'] != null) header["MUSIC_U"] = cookie['MUSIC_U'];
    if (cookie['MUSIC_A']) header["MUSIC_A"] = cookie['MUSIC_A'];
    header['Cookie'] = header.keys
        .map((key) =>
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(header[key])}')
        .join('; ');

    data['header'] = header;
    data = eapi(url, data);
    url = url.replaceAll(RegExp(r"\w*api"), 'eapi');
  }

  var answer = Completer<Answer>.sync();

  HttpClient().openUrl(method, Uri.parse(url)).then((request) {
    headers.forEach(request.headers.add);
    request.write(Uri(queryParameters: data.cast()).query);
    return request.close();
  }).then((response) async {
    var ans = Answer(cookie: response.cookies);
    final content = await response.transform(utf8.decoder).join();
    final body = json.decode(content);
    ans = ans.copy(
        status: int.parse(body['code'].toString()) ?? response.statusCode,
        body: body);

    ans = ans.copy(
        status: ans.status > 100 && ans.status < 600 ? ans.status : 400);
    answer.complete(ans);
  }).catchError((e, StackTrace s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
    answer.complete(
        Answer(status: 502, body: {'code': 502, 'msg': e.toString()}));
  });
  return answer.future;
}

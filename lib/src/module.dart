import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'answer.dart';
import 'util/request.dart';
import 'util/utils.dart';

part 'module/album.dart';
part 'module/artist.dart';
part 'module/banner.dart';
part 'module/batch.dart';
part 'module/captch.dart';
part 'module/check_music.dart';
part 'module/comment.dart';
part 'module/daily_signin.dart';
part 'module/digitalAlbum_purchased.dart';
part 'module/dj.dart';
part 'module/event.dart';
part 'module/fm.dart';
part 'module/follow.dart';
part 'module/hot.dart';
part 'module/like.dart';
part 'module/login.dart';
part 'module/lyric.dart';
part 'module/msg.dart';
part 'module/mv.dart';

typedef Handler = Future<Answer> Function(Map query, List<Cookie> cookie);

final handles = <String, Handler>{
  "/album/newest": album_newest,
  "/album/sublist": album_sublist,
  "/album": album,
  "/artist/album": artist_album,
  "/artist/desc": artist_desc,
  "/artist/list": artist_list,
  "/artist/mv": artist_mv,
  "/artist/sub": artist_sub,
  "/artist/sublist": artist_sublist,
  "/artists": artists,
  "/banner": banner,
  "/batch": batch,
  "/captch/register": captch_register,
  "/captch/send": captch_send,
  "/captch/verify": captch_verify,
  "/comment/album": comment_album,
  "/comment/dj": comment_dj,
  "/comment/events": comment_events,
  "/comment/hot": comment_hot,
  "/comment/like": comment_like,
  "/comment/music": comment_music,
  "/comment/mv": comment_mv,
  "/comment/playlist": comment_playlist,
  "/comment/video": comment_video,
  "/comment": comment,
  "/daily/signin": daily_signin,
  "/digitalAlbum/purchased": digitalAlbum_purchased,
  "/dj/banner": dj_banner,
  "/dj/category/excludehot": dj_category_excludehot,
  "/dj/category/recommend": dj_category_recommend,
  "/dj/catelist": dj_catelist,
  "/dj/detail": dj_detail,
  "/dj/hot": dj_hot,
  "/dj/paygift": dj_paygift,
  "/dj/program/detail": dj_program_detail,
  "/dj/recommend/type": dj_recommend_type,
  "/dj/recommend": dj_recommend,
  "/dj/sub": dj_sub,
  "/dj/sublist": dj_sublist,
  "/dj/today_perfered": dj_today_perfered,
  "/event/del": event_del,
  "/event/forward": event_forward,
  "/event": event,
};

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Missing videoId');
    exit(1);
  }
  final videoId = args[0].trim();
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    final audio = manifest.audioOnly.withHighestBitrate();
    stdout.writeln(audio.url.toString());
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  } finally {
    yt.close();
  }
}

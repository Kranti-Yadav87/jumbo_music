library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'update_user.dart';

part 'delete_user.dart';

part 'get_user.dart';

part 'list_users.dart';

part 'create_playlist.dart';

part 'update_playlist.dart';

part 'delete_playlist.dart';

part 'get_playlist.dart';

part 'list_playlists.dart';

part 'create_love_note.dart';

part 'update_love_note.dart';

part 'delete_love_note.dart';

part 'get_love_note.dart';

part 'list_love_notes.dart';

part 'heart_playlist.dart';

part 'unheart_playlist.dart';

part 'list_hearts.dart';

part 'follow_user.dart';

part 'unfollow_user.dart';

part 'list_following.dart';

part 'add_track.dart';

part 'update_track.dart';

part 'delete_track.dart';

part 'get_track.dart';

part 'list_tracks.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser ({required String username, required String email, }) {
    return CreateUserVariablesBuilder(dataConnect, username: username,email: email,);
  }
  
  
  UpdateUserVariablesBuilder updateUser () {
    return UpdateUserVariablesBuilder(dataConnect, );
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  GetUserVariablesBuilder getUser () {
    return GetUserVariablesBuilder(dataConnect, );
  }
  
  
  ListUsersVariablesBuilder listUsers () {
    return ListUsersVariablesBuilder(dataConnect, );
  }
  
  
  CreatePlaylistVariablesBuilder createPlaylist ({required String title, }) {
    return CreatePlaylistVariablesBuilder(dataConnect, title: title,);
  }
  
  
  UpdatePlaylistVariablesBuilder updatePlaylist ({required String id, }) {
    return UpdatePlaylistVariablesBuilder(dataConnect, id: id,);
  }
  
  
  DeletePlaylistVariablesBuilder deletePlaylist ({required String id, }) {
    return DeletePlaylistVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetPlaylistVariablesBuilder getPlaylist ({required String id, }) {
    return GetPlaylistVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListPlaylistsVariablesBuilder listPlaylists () {
    return ListPlaylistsVariablesBuilder(dataConnect, );
  }
  
  
  CreateLoveNoteVariablesBuilder createLoveNote ({required String playlistId, required String trackId, required String message, }) {
    return CreateLoveNoteVariablesBuilder(dataConnect, playlistId: playlistId,trackId: trackId,message: message,);
  }
  
  
  UpdateLoveNoteVariablesBuilder updateLoveNote ({required String id, required String message, }) {
    return UpdateLoveNoteVariablesBuilder(dataConnect, id: id,message: message,);
  }
  
  
  DeleteLoveNoteVariablesBuilder deleteLoveNote ({required String id, }) {
    return DeleteLoveNoteVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetLoveNoteVariablesBuilder getLoveNote ({required String id, }) {
    return GetLoveNoteVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListLoveNotesVariablesBuilder listLoveNotes () {
    return ListLoveNotesVariablesBuilder(dataConnect, );
  }
  
  
  HeartPlaylistVariablesBuilder heartPlaylist ({required String playlistId, }) {
    return HeartPlaylistVariablesBuilder(dataConnect, playlistId: playlistId,);
  }
  
  
  UnheartPlaylistVariablesBuilder unheartPlaylist ({required String id, }) {
    return UnheartPlaylistVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListHeartsVariablesBuilder listHearts () {
    return ListHeartsVariablesBuilder(dataConnect, );
  }
  
  
  FollowUserVariablesBuilder followUser ({required String followingId, }) {
    return FollowUserVariablesBuilder(dataConnect, followingId: followingId,);
  }
  
  
  UnfollowUserVariablesBuilder unfollowUser ({required String id, }) {
    return UnfollowUserVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListFollowingVariablesBuilder listFollowing () {
    return ListFollowingVariablesBuilder(dataConnect, );
  }
  
  
  AddTrackVariablesBuilder addTrack ({required String title, required String artistName, required String externalUrl, }) {
    return AddTrackVariablesBuilder(dataConnect, title: title,artistName: artistName,externalUrl: externalUrl,);
  }
  
  
  UpdateTrackVariablesBuilder updateTrack ({required String id, }) {
    return UpdateTrackVariablesBuilder(dataConnect, id: id,);
  }
  
  
  DeleteTrackVariablesBuilder deleteTrack ({required String id, }) {
    return DeleteTrackVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetTrackVariablesBuilder getTrack ({required String id, }) {
    return GetTrackVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListTracksVariablesBuilder listTracks () {
    return ListTracksVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'jumbomusic-main',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}

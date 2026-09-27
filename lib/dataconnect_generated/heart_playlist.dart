part of 'generated.dart';

class HeartPlaylistVariablesBuilder {
  String playlistId;

  final FirebaseDataConnect _dataConnect;
  HeartPlaylistVariablesBuilder(this._dataConnect, {required  this.playlistId,});
  Deserializer<HeartPlaylistData> dataDeserializer = (dynamic json)  => HeartPlaylistData.fromJson(jsonDecode(json));
  Serializer<HeartPlaylistVariables> varsSerializer = (HeartPlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<HeartPlaylistData, HeartPlaylistVariables>> execute() {
    return ref().execute();
  }

  MutationRef<HeartPlaylistData, HeartPlaylistVariables> ref() {
    HeartPlaylistVariables vars= HeartPlaylistVariables(playlistId: playlistId,);
    return _dataConnect.mutation("HeartPlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class HeartPlaylistHeartInsert {
  final String id;
  HeartPlaylistHeartInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final HeartPlaylistHeartInsert otherTyped = other as HeartPlaylistHeartInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  HeartPlaylistHeartInsert({
    required this.id,
  });
}

@immutable
class HeartPlaylistData {
  final HeartPlaylistHeartInsert heart_insert;
  HeartPlaylistData.fromJson(dynamic json):
  
  heart_insert = HeartPlaylistHeartInsert.fromJson(json['heart_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final HeartPlaylistData otherTyped = other as HeartPlaylistData;
    return heart_insert == otherTyped.heart_insert;
    
  }
  @override
  int get hashCode => heart_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['heart_insert'] = heart_insert.toJson();
    return json;
  }

  HeartPlaylistData({
    required this.heart_insert,
  });
}

@immutable
class HeartPlaylistVariables {
  final String playlistId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  HeartPlaylistVariables.fromJson(Map<String, dynamic> json):
  
  playlistId = nativeFromJson<String>(json['playlistId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final HeartPlaylistVariables otherTyped = other as HeartPlaylistVariables;
    return playlistId == otherTyped.playlistId;
    
  }
  @override
  int get hashCode => playlistId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['playlistId'] = nativeToJson<String>(playlistId);
    return json;
  }

  HeartPlaylistVariables({
    required this.playlistId,
  });
}


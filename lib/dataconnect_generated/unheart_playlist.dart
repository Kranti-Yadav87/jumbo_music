part of 'generated.dart';

class UnheartPlaylistVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  UnheartPlaylistVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UnheartPlaylistData> dataDeserializer = (dynamic json)  => UnheartPlaylistData.fromJson(jsonDecode(json));
  Serializer<UnheartPlaylistVariables> varsSerializer = (UnheartPlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UnheartPlaylistData, UnheartPlaylistVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UnheartPlaylistData, UnheartPlaylistVariables> ref() {
    UnheartPlaylistVariables vars= UnheartPlaylistVariables(id: id,);
    return _dataConnect.mutation("UnheartPlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UnheartPlaylistHeartDelete {
  final String id;
  UnheartPlaylistHeartDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnheartPlaylistHeartDelete otherTyped = other as UnheartPlaylistHeartDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UnheartPlaylistHeartDelete({
    required this.id,
  });
}

@immutable
class UnheartPlaylistData {
  final UnheartPlaylistHeartDelete? heart_delete;
  UnheartPlaylistData.fromJson(dynamic json):
  
  heart_delete = json['heart_delete'] == null ? null : UnheartPlaylistHeartDelete.fromJson(json['heart_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnheartPlaylistData otherTyped = other as UnheartPlaylistData;
    return heart_delete == otherTyped.heart_delete;
    
  }
  @override
  int get hashCode => heart_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (heart_delete != null) {
      json['heart_delete'] = heart_delete!.toJson();
    }
    return json;
  }

  UnheartPlaylistData({
    this.heart_delete,
  });
}

@immutable
class UnheartPlaylistVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UnheartPlaylistVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnheartPlaylistVariables otherTyped = other as UnheartPlaylistVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UnheartPlaylistVariables({
    required this.id,
  });
}


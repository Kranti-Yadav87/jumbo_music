part of 'generated.dart';

class DeletePlaylistVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeletePlaylistVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeletePlaylistData> dataDeserializer = (dynamic json)  => DeletePlaylistData.fromJson(jsonDecode(json));
  Serializer<DeletePlaylistVariables> varsSerializer = (DeletePlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeletePlaylistData, DeletePlaylistVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeletePlaylistData, DeletePlaylistVariables> ref() {
    DeletePlaylistVariables vars= DeletePlaylistVariables(id: id,);
    return _dataConnect.mutation("DeletePlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeletePlaylistPlaylistDelete {
  final String id;
  DeletePlaylistPlaylistDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeletePlaylistPlaylistDelete otherTyped = other as DeletePlaylistPlaylistDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeletePlaylistPlaylistDelete({
    required this.id,
  });
}

@immutable
class DeletePlaylistData {
  final DeletePlaylistPlaylistDelete? playlist_delete;
  DeletePlaylistData.fromJson(dynamic json):
  
  playlist_delete = json['playlist_delete'] == null ? null : DeletePlaylistPlaylistDelete.fromJson(json['playlist_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeletePlaylistData otherTyped = other as DeletePlaylistData;
    return playlist_delete == otherTyped.playlist_delete;
    
  }
  @override
  int get hashCode => playlist_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (playlist_delete != null) {
      json['playlist_delete'] = playlist_delete!.toJson();
    }
    return json;
  }

  DeletePlaylistData({
    this.playlist_delete,
  });
}

@immutable
class DeletePlaylistVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeletePlaylistVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeletePlaylistVariables otherTyped = other as DeletePlaylistVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeletePlaylistVariables({
    required this.id,
  });
}


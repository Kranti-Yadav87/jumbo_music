part of 'generated.dart';

class UpdatePlaylistVariablesBuilder {
  String id;
  Optional<String> _title = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _description = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _isPublic = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdatePlaylistVariablesBuilder title(String? t) {
   _title.value = t;
   return this;
  }
  UpdatePlaylistVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpdatePlaylistVariablesBuilder isPublic(bool? t) {
   _isPublic.value = t;
   return this;
  }

  UpdatePlaylistVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdatePlaylistData> dataDeserializer = (dynamic json)  => UpdatePlaylistData.fromJson(jsonDecode(json));
  Serializer<UpdatePlaylistVariables> varsSerializer = (UpdatePlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdatePlaylistData, UpdatePlaylistVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdatePlaylistData, UpdatePlaylistVariables> ref() {
    UpdatePlaylistVariables vars= UpdatePlaylistVariables(id: id,title: _title,description: _description,isPublic: _isPublic,);
    return _dataConnect.mutation("UpdatePlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdatePlaylistPlaylistUpdate {
  final String id;
  UpdatePlaylistPlaylistUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlaylistPlaylistUpdate otherTyped = other as UpdatePlaylistPlaylistUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdatePlaylistPlaylistUpdate({
    required this.id,
  });
}

@immutable
class UpdatePlaylistData {
  final UpdatePlaylistPlaylistUpdate? playlist_update;
  UpdatePlaylistData.fromJson(dynamic json):
  
  playlist_update = json['playlist_update'] == null ? null : UpdatePlaylistPlaylistUpdate.fromJson(json['playlist_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlaylistData otherTyped = other as UpdatePlaylistData;
    return playlist_update == otherTyped.playlist_update;
    
  }
  @override
  int get hashCode => playlist_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (playlist_update != null) {
      json['playlist_update'] = playlist_update!.toJson();
    }
    return json;
  }

  UpdatePlaylistData({
    this.playlist_update,
  });
}

@immutable
class UpdatePlaylistVariables {
  final String id;
  late final Optional<String>title;
  late final Optional<String>description;
  late final Optional<bool>isPublic;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdatePlaylistVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    title = Optional.optional(nativeFromJson, nativeToJson);
    title.value = json['title'] == null ? null : nativeFromJson<String>(json['title']);
  
  
    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  
  
    isPublic = Optional.optional(nativeFromJson, nativeToJson);
    isPublic.value = json['isPublic'] == null ? null : nativeFromJson<bool>(json['isPublic']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlaylistVariables otherTyped = other as UpdatePlaylistVariables;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    description == otherTyped.description && 
    isPublic == otherTyped.isPublic;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, description.hashCode, isPublic.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(title.state == OptionalState.set) {
      json['title'] = title.toJson();
    }
    if(description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    if(isPublic.state == OptionalState.set) {
      json['isPublic'] = isPublic.toJson();
    }
    return json;
  }

  UpdatePlaylistVariables({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublic,
  });
}


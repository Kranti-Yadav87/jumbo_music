part of 'generated.dart';

class CreatePlaylistVariablesBuilder {
  String title;
  Optional<String> _description = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _isPublic = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreatePlaylistVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  CreatePlaylistVariablesBuilder isPublic(bool? t) {
   _isPublic.value = t;
   return this;
  }

  CreatePlaylistVariablesBuilder(this._dataConnect, {required  this.title,});
  Deserializer<CreatePlaylistData> dataDeserializer = (dynamic json)  => CreatePlaylistData.fromJson(jsonDecode(json));
  Serializer<CreatePlaylistVariables> varsSerializer = (CreatePlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreatePlaylistData, CreatePlaylistVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreatePlaylistData, CreatePlaylistVariables> ref() {
    CreatePlaylistVariables vars= CreatePlaylistVariables(title: title,description: _description,isPublic: _isPublic,);
    return _dataConnect.mutation("CreatePlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreatePlaylistPlaylistInsert {
  final String id;
  CreatePlaylistPlaylistInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePlaylistPlaylistInsert otherTyped = other as CreatePlaylistPlaylistInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreatePlaylistPlaylistInsert({
    required this.id,
  });
}

@immutable
class CreatePlaylistData {
  final CreatePlaylistPlaylistInsert playlist_insert;
  CreatePlaylistData.fromJson(dynamic json):
  
  playlist_insert = CreatePlaylistPlaylistInsert.fromJson(json['playlist_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePlaylistData otherTyped = other as CreatePlaylistData;
    return playlist_insert == otherTyped.playlist_insert;
    
  }
  @override
  int get hashCode => playlist_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['playlist_insert'] = playlist_insert.toJson();
    return json;
  }

  CreatePlaylistData({
    required this.playlist_insert,
  });
}

@immutable
class CreatePlaylistVariables {
  final String title;
  late final Optional<String>description;
  late final Optional<bool>isPublic;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreatePlaylistVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']) {
  
  
  
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

    final CreatePlaylistVariables otherTyped = other as CreatePlaylistVariables;
    return title == otherTyped.title && 
    description == otherTyped.description && 
    isPublic == otherTyped.isPublic;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, description.hashCode, isPublic.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    if(description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    if(isPublic.state == OptionalState.set) {
      json['isPublic'] = isPublic.toJson();
    }
    return json;
  }

  CreatePlaylistVariables({
    required this.title,
    required this.description,
    required this.isPublic,
  });
}


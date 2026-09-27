part of 'generated.dart';

class GetPlaylistVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetPlaylistVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetPlaylistData> dataDeserializer = (dynamic json)  => GetPlaylistData.fromJson(jsonDecode(json));
  Serializer<GetPlaylistVariables> varsSerializer = (GetPlaylistVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPlaylistData, GetPlaylistVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetPlaylistData, GetPlaylistVariables> ref() {
    GetPlaylistVariables vars= GetPlaylistVariables(id: id,);
    return _dataConnect.query("GetPlaylist", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPlaylistPlaylist {
  final String title;
  final GetPlaylistPlaylistCreator creator;
  final String? description;
  GetPlaylistPlaylist.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  creator = GetPlaylistPlaylistCreator.fromJson(json['creator']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlaylistPlaylist otherTyped = other as GetPlaylistPlaylist;
    return title == otherTyped.title && 
    creator == otherTyped.creator && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, creator.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['creator'] = creator.toJson();
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  GetPlaylistPlaylist({
    required this.title,
    required this.creator,
    this.description,
  });
}

@immutable
class GetPlaylistPlaylistCreator {
  final String username;
  GetPlaylistPlaylistCreator.fromJson(dynamic json):
  
  username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlaylistPlaylistCreator otherTyped = other as GetPlaylistPlaylistCreator;
    return username == otherTyped.username;
    
  }
  @override
  int get hashCode => username.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    return json;
  }

  GetPlaylistPlaylistCreator({
    required this.username,
  });
}

@immutable
class GetPlaylistData {
  final GetPlaylistPlaylist? playlist;
  GetPlaylistData.fromJson(dynamic json):
  
  playlist = json['playlist'] == null ? null : GetPlaylistPlaylist.fromJson(json['playlist']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlaylistData otherTyped = other as GetPlaylistData;
    return playlist == otherTyped.playlist;
    
  }
  @override
  int get hashCode => playlist.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (playlist != null) {
      json['playlist'] = playlist!.toJson();
    }
    return json;
  }

  GetPlaylistData({
    this.playlist,
  });
}

@immutable
class GetPlaylistVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPlaylistVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlaylistVariables otherTyped = other as GetPlaylistVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetPlaylistVariables({
    required this.id,
  });
}


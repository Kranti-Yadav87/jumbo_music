part of 'generated.dart';

class ListPlaylistsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListPlaylistsVariablesBuilder(this._dataConnect, );
  Deserializer<ListPlaylistsData> dataDeserializer = (dynamic json)  => ListPlaylistsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListPlaylistsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListPlaylistsData, void> ref() {
    
    return _dataConnect.query("ListPlaylists", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListPlaylistsPlaylists {
  final String title;
  final ListPlaylistsPlaylistsCreator creator;
  ListPlaylistsPlaylists.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  creator = ListPlaylistsPlaylistsCreator.fromJson(json['creator']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlaylistsPlaylists otherTyped = other as ListPlaylistsPlaylists;
    return title == otherTyped.title && 
    creator == otherTyped.creator;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, creator.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['creator'] = creator.toJson();
    return json;
  }

  ListPlaylistsPlaylists({
    required this.title,
    required this.creator,
  });
}

@immutable
class ListPlaylistsPlaylistsCreator {
  final String username;
  ListPlaylistsPlaylistsCreator.fromJson(dynamic json):
  
  username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlaylistsPlaylistsCreator otherTyped = other as ListPlaylistsPlaylistsCreator;
    return username == otherTyped.username;
    
  }
  @override
  int get hashCode => username.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    return json;
  }

  ListPlaylistsPlaylistsCreator({
    required this.username,
  });
}

@immutable
class ListPlaylistsData {
  final List<ListPlaylistsPlaylists> playlists;
  ListPlaylistsData.fromJson(dynamic json):
  
  playlists = (json['playlists'] as List<dynamic>)
        .map((e) => ListPlaylistsPlaylists.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlaylistsData otherTyped = other as ListPlaylistsData;
    return playlists == otherTyped.playlists;
    
  }
  @override
  int get hashCode => playlists.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['playlists'] = playlists.map((e) => e.toJson()).toList();
    return json;
  }

  ListPlaylistsData({
    required this.playlists,
  });
}


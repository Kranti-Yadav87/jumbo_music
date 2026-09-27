part of 'generated.dart';

class ListHeartsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListHeartsVariablesBuilder(this._dataConnect, );
  Deserializer<ListHeartsData> dataDeserializer = (dynamic json)  => ListHeartsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListHeartsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListHeartsData, void> ref() {
    
    return _dataConnect.query("ListHearts", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListHeartsHearts {
  final ListHeartsHeartsPlaylist playlist;
  ListHeartsHearts.fromJson(dynamic json):
  
  playlist = ListHeartsHeartsPlaylist.fromJson(json['playlist']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListHeartsHearts otherTyped = other as ListHeartsHearts;
    return playlist == otherTyped.playlist;
    
  }
  @override
  int get hashCode => playlist.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['playlist'] = playlist.toJson();
    return json;
  }

  ListHeartsHearts({
    required this.playlist,
  });
}

@immutable
class ListHeartsHeartsPlaylist {
  final String title;
  ListHeartsHeartsPlaylist.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListHeartsHeartsPlaylist otherTyped = other as ListHeartsHeartsPlaylist;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  ListHeartsHeartsPlaylist({
    required this.title,
  });
}

@immutable
class ListHeartsData {
  final List<ListHeartsHearts> hearts;
  ListHeartsData.fromJson(dynamic json):
  
  hearts = (json['hearts'] as List<dynamic>)
        .map((e) => ListHeartsHearts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListHeartsData otherTyped = other as ListHeartsData;
    return hearts == otherTyped.hearts;
    
  }
  @override
  int get hashCode => hearts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['hearts'] = hearts.map((e) => e.toJson()).toList();
    return json;
  }

  ListHeartsData({
    required this.hearts,
  });
}


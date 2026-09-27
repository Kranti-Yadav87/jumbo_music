part of 'generated.dart';

class ListTracksVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListTracksVariablesBuilder(this._dataConnect, );
  Deserializer<ListTracksData> dataDeserializer = (dynamic json)  => ListTracksData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListTracksData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListTracksData, void> ref() {
    
    return _dataConnect.query("ListTracks", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListTracksTracks {
  final String title;
  final String artistName;
  ListTracksTracks.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  artistName = nativeFromJson<String>(json['artistName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTracksTracks otherTyped = other as ListTracksTracks;
    return title == otherTyped.title && 
    artistName == otherTyped.artistName;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, artistName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['artistName'] = nativeToJson<String>(artistName);
    return json;
  }

  ListTracksTracks({
    required this.title,
    required this.artistName,
  });
}

@immutable
class ListTracksData {
  final List<ListTracksTracks> tracks;
  ListTracksData.fromJson(dynamic json):
  
  tracks = (json['tracks'] as List<dynamic>)
        .map((e) => ListTracksTracks.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTracksData otherTyped = other as ListTracksData;
    return tracks == otherTyped.tracks;
    
  }
  @override
  int get hashCode => tracks.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['tracks'] = tracks.map((e) => e.toJson()).toList();
    return json;
  }

  ListTracksData({
    required this.tracks,
  });
}


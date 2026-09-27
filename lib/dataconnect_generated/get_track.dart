part of 'generated.dart';

class GetTrackVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetTrackVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetTrackData> dataDeserializer = (dynamic json)  => GetTrackData.fromJson(jsonDecode(json));
  Serializer<GetTrackVariables> varsSerializer = (GetTrackVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTrackData, GetTrackVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetTrackData, GetTrackVariables> ref() {
    GetTrackVariables vars= GetTrackVariables(id: id,);
    return _dataConnect.query("GetTrack", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetTrackTrack {
  final String title;
  final String artistName;
  final String externalUrl;
  GetTrackTrack.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  artistName = nativeFromJson<String>(json['artistName']),
  externalUrl = nativeFromJson<String>(json['externalUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTrackTrack otherTyped = other as GetTrackTrack;
    return title == otherTyped.title && 
    artistName == otherTyped.artistName && 
    externalUrl == otherTyped.externalUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, artistName.hashCode, externalUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['artistName'] = nativeToJson<String>(artistName);
    json['externalUrl'] = nativeToJson<String>(externalUrl);
    return json;
  }

  GetTrackTrack({
    required this.title,
    required this.artistName,
    required this.externalUrl,
  });
}

@immutable
class GetTrackData {
  final GetTrackTrack? track;
  GetTrackData.fromJson(dynamic json):
  
  track = json['track'] == null ? null : GetTrackTrack.fromJson(json['track']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTrackData otherTyped = other as GetTrackData;
    return track == otherTyped.track;
    
  }
  @override
  int get hashCode => track.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (track != null) {
      json['track'] = track!.toJson();
    }
    return json;
  }

  GetTrackData({
    this.track,
  });
}

@immutable
class GetTrackVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetTrackVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTrackVariables otherTyped = other as GetTrackVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetTrackVariables({
    required this.id,
  });
}


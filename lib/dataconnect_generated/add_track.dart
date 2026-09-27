part of 'generated.dart';

class AddTrackVariablesBuilder {
  String title;
  String artistName;
  String externalUrl;
  Optional<String> _albumName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _genre = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  AddTrackVariablesBuilder albumName(String? t) {
   _albumName.value = t;
   return this;
  }
  AddTrackVariablesBuilder genre(String? t) {
   _genre.value = t;
   return this;
  }

  AddTrackVariablesBuilder(this._dataConnect, {required  this.title,required  this.artistName,required  this.externalUrl,});
  Deserializer<AddTrackData> dataDeserializer = (dynamic json)  => AddTrackData.fromJson(jsonDecode(json));
  Serializer<AddTrackVariables> varsSerializer = (AddTrackVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddTrackData, AddTrackVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddTrackData, AddTrackVariables> ref() {
    AddTrackVariables vars= AddTrackVariables(title: title,artistName: artistName,externalUrl: externalUrl,albumName: _albumName,genre: _genre,);
    return _dataConnect.mutation("AddTrack", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddTrackTrackInsert {
  final String id;
  AddTrackTrackInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTrackTrackInsert otherTyped = other as AddTrackTrackInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddTrackTrackInsert({
    required this.id,
  });
}

@immutable
class AddTrackData {
  final AddTrackTrackInsert track_insert;
  AddTrackData.fromJson(dynamic json):
  
  track_insert = AddTrackTrackInsert.fromJson(json['track_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTrackData otherTyped = other as AddTrackData;
    return track_insert == otherTyped.track_insert;
    
  }
  @override
  int get hashCode => track_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['track_insert'] = track_insert.toJson();
    return json;
  }

  AddTrackData({
    required this.track_insert,
  });
}

@immutable
class AddTrackVariables {
  final String title;
  final String artistName;
  final String externalUrl;
  late final Optional<String>albumName;
  late final Optional<String>genre;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddTrackVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']),
  artistName = nativeFromJson<String>(json['artistName']),
  externalUrl = nativeFromJson<String>(json['externalUrl']) {
  
  
  
  
  
    albumName = Optional.optional(nativeFromJson, nativeToJson);
    albumName.value = json['albumName'] == null ? null : nativeFromJson<String>(json['albumName']);
  
  
    genre = Optional.optional(nativeFromJson, nativeToJson);
    genre.value = json['genre'] == null ? null : nativeFromJson<String>(json['genre']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTrackVariables otherTyped = other as AddTrackVariables;
    return title == otherTyped.title && 
    artistName == otherTyped.artistName && 
    externalUrl == otherTyped.externalUrl && 
    albumName == otherTyped.albumName && 
    genre == otherTyped.genre;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, artistName.hashCode, externalUrl.hashCode, albumName.hashCode, genre.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['artistName'] = nativeToJson<String>(artistName);
    json['externalUrl'] = nativeToJson<String>(externalUrl);
    if(albumName.state == OptionalState.set) {
      json['albumName'] = albumName.toJson();
    }
    if(genre.state == OptionalState.set) {
      json['genre'] = genre.toJson();
    }
    return json;
  }

  AddTrackVariables({
    required this.title,
    required this.artistName,
    required this.externalUrl,
    required this.albumName,
    required this.genre,
  });
}


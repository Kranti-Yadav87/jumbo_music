part of 'generated.dart';

class UpdateTrackVariablesBuilder {
  String id;
  Optional<String> _genre = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateTrackVariablesBuilder genre(String? t) {
   _genre.value = t;
   return this;
  }

  UpdateTrackVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdateTrackData> dataDeserializer = (dynamic json)  => UpdateTrackData.fromJson(jsonDecode(json));
  Serializer<UpdateTrackVariables> varsSerializer = (UpdateTrackVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTrackData, UpdateTrackVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTrackData, UpdateTrackVariables> ref() {
    UpdateTrackVariables vars= UpdateTrackVariables(id: id,genre: _genre,);
    return _dataConnect.mutation("UpdateTrack", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTrackTrackUpdate {
  final String id;
  UpdateTrackTrackUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTrackTrackUpdate otherTyped = other as UpdateTrackTrackUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTrackTrackUpdate({
    required this.id,
  });
}

@immutable
class UpdateTrackData {
  final UpdateTrackTrackUpdate? track_update;
  UpdateTrackData.fromJson(dynamic json):
  
  track_update = json['track_update'] == null ? null : UpdateTrackTrackUpdate.fromJson(json['track_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTrackData otherTyped = other as UpdateTrackData;
    return track_update == otherTyped.track_update;
    
  }
  @override
  int get hashCode => track_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (track_update != null) {
      json['track_update'] = track_update!.toJson();
    }
    return json;
  }

  UpdateTrackData({
    this.track_update,
  });
}

@immutable
class UpdateTrackVariables {
  final String id;
  late final Optional<String>genre;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTrackVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
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

    final UpdateTrackVariables otherTyped = other as UpdateTrackVariables;
    return id == otherTyped.id && 
    genre == otherTyped.genre;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, genre.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(genre.state == OptionalState.set) {
      json['genre'] = genre.toJson();
    }
    return json;
  }

  UpdateTrackVariables({
    required this.id,
    required this.genre,
  });
}


part of 'generated.dart';

class DeleteTrackVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteTrackVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteTrackData> dataDeserializer = (dynamic json)  => DeleteTrackData.fromJson(jsonDecode(json));
  Serializer<DeleteTrackVariables> varsSerializer = (DeleteTrackVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteTrackData, DeleteTrackVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteTrackData, DeleteTrackVariables> ref() {
    DeleteTrackVariables vars= DeleteTrackVariables(id: id,);
    return _dataConnect.mutation("DeleteTrack", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteTrackTrackDelete {
  final String id;
  DeleteTrackTrackDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTrackTrackDelete otherTyped = other as DeleteTrackTrackDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteTrackTrackDelete({
    required this.id,
  });
}

@immutable
class DeleteTrackData {
  final DeleteTrackTrackDelete? track_delete;
  DeleteTrackData.fromJson(dynamic json):
  
  track_delete = json['track_delete'] == null ? null : DeleteTrackTrackDelete.fromJson(json['track_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTrackData otherTyped = other as DeleteTrackData;
    return track_delete == otherTyped.track_delete;
    
  }
  @override
  int get hashCode => track_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (track_delete != null) {
      json['track_delete'] = track_delete!.toJson();
    }
    return json;
  }

  DeleteTrackData({
    this.track_delete,
  });
}

@immutable
class DeleteTrackVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteTrackVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTrackVariables otherTyped = other as DeleteTrackVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteTrackVariables({
    required this.id,
  });
}


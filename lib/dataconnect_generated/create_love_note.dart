part of 'generated.dart';

class CreateLoveNoteVariablesBuilder {
  String playlistId;
  String trackId;
  String message;

  final FirebaseDataConnect _dataConnect;
  CreateLoveNoteVariablesBuilder(this._dataConnect, {required  this.playlistId,required  this.trackId,required  this.message,});
  Deserializer<CreateLoveNoteData> dataDeserializer = (dynamic json)  => CreateLoveNoteData.fromJson(jsonDecode(json));
  Serializer<CreateLoveNoteVariables> varsSerializer = (CreateLoveNoteVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateLoveNoteData, CreateLoveNoteVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateLoveNoteData, CreateLoveNoteVariables> ref() {
    CreateLoveNoteVariables vars= CreateLoveNoteVariables(playlistId: playlistId,trackId: trackId,message: message,);
    return _dataConnect.mutation("CreateLoveNote", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateLoveNoteLoveNoteInsert {
  final String id;
  CreateLoveNoteLoveNoteInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLoveNoteLoveNoteInsert otherTyped = other as CreateLoveNoteLoveNoteInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateLoveNoteLoveNoteInsert({
    required this.id,
  });
}

@immutable
class CreateLoveNoteData {
  final CreateLoveNoteLoveNoteInsert loveNote_insert;
  CreateLoveNoteData.fromJson(dynamic json):
  
  loveNote_insert = CreateLoveNoteLoveNoteInsert.fromJson(json['loveNote_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLoveNoteData otherTyped = other as CreateLoveNoteData;
    return loveNote_insert == otherTyped.loveNote_insert;
    
  }
  @override
  int get hashCode => loveNote_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['loveNote_insert'] = loveNote_insert.toJson();
    return json;
  }

  CreateLoveNoteData({
    required this.loveNote_insert,
  });
}

@immutable
class CreateLoveNoteVariables {
  final String playlistId;
  final String trackId;
  final String message;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateLoveNoteVariables.fromJson(Map<String, dynamic> json):
  
  playlistId = nativeFromJson<String>(json['playlistId']),
  trackId = nativeFromJson<String>(json['trackId']),
  message = nativeFromJson<String>(json['message']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLoveNoteVariables otherTyped = other as CreateLoveNoteVariables;
    return playlistId == otherTyped.playlistId && 
    trackId == otherTyped.trackId && 
    message == otherTyped.message;
    
  }
  @override
  int get hashCode => Object.hashAll([playlistId.hashCode, trackId.hashCode, message.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['playlistId'] = nativeToJson<String>(playlistId);
    json['trackId'] = nativeToJson<String>(trackId);
    json['message'] = nativeToJson<String>(message);
    return json;
  }

  CreateLoveNoteVariables({
    required this.playlistId,
    required this.trackId,
    required this.message,
  });
}


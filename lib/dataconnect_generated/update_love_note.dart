part of 'generated.dart';

class UpdateLoveNoteVariablesBuilder {
  String id;
  String message;

  final FirebaseDataConnect _dataConnect;
  UpdateLoveNoteVariablesBuilder(this._dataConnect, {required  this.id,required  this.message,});
  Deserializer<UpdateLoveNoteData> dataDeserializer = (dynamic json)  => UpdateLoveNoteData.fromJson(jsonDecode(json));
  Serializer<UpdateLoveNoteVariables> varsSerializer = (UpdateLoveNoteVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateLoveNoteData, UpdateLoveNoteVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateLoveNoteData, UpdateLoveNoteVariables> ref() {
    UpdateLoveNoteVariables vars= UpdateLoveNoteVariables(id: id,message: message,);
    return _dataConnect.mutation("UpdateLoveNote", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateLoveNoteLoveNoteUpdate {
  final String id;
  UpdateLoveNoteLoveNoteUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLoveNoteLoveNoteUpdate otherTyped = other as UpdateLoveNoteLoveNoteUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateLoveNoteLoveNoteUpdate({
    required this.id,
  });
}

@immutable
class UpdateLoveNoteData {
  final UpdateLoveNoteLoveNoteUpdate? loveNote_update;
  UpdateLoveNoteData.fromJson(dynamic json):
  
  loveNote_update = json['loveNote_update'] == null ? null : UpdateLoveNoteLoveNoteUpdate.fromJson(json['loveNote_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLoveNoteData otherTyped = other as UpdateLoveNoteData;
    return loveNote_update == otherTyped.loveNote_update;
    
  }
  @override
  int get hashCode => loveNote_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (loveNote_update != null) {
      json['loveNote_update'] = loveNote_update!.toJson();
    }
    return json;
  }

  UpdateLoveNoteData({
    this.loveNote_update,
  });
}

@immutable
class UpdateLoveNoteVariables {
  final String id;
  final String message;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateLoveNoteVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  message = nativeFromJson<String>(json['message']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLoveNoteVariables otherTyped = other as UpdateLoveNoteVariables;
    return id == otherTyped.id && 
    message == otherTyped.message;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, message.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['message'] = nativeToJson<String>(message);
    return json;
  }

  UpdateLoveNoteVariables({
    required this.id,
    required this.message,
  });
}


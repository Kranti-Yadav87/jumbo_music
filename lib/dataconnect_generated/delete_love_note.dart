part of 'generated.dart';

class DeleteLoveNoteVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteLoveNoteVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteLoveNoteData> dataDeserializer = (dynamic json)  => DeleteLoveNoteData.fromJson(jsonDecode(json));
  Serializer<DeleteLoveNoteVariables> varsSerializer = (DeleteLoveNoteVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteLoveNoteData, DeleteLoveNoteVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteLoveNoteData, DeleteLoveNoteVariables> ref() {
    DeleteLoveNoteVariables vars= DeleteLoveNoteVariables(id: id,);
    return _dataConnect.mutation("DeleteLoveNote", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteLoveNoteLoveNoteDelete {
  final String id;
  DeleteLoveNoteLoveNoteDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLoveNoteLoveNoteDelete otherTyped = other as DeleteLoveNoteLoveNoteDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteLoveNoteLoveNoteDelete({
    required this.id,
  });
}

@immutable
class DeleteLoveNoteData {
  final DeleteLoveNoteLoveNoteDelete? loveNote_delete;
  DeleteLoveNoteData.fromJson(dynamic json):
  
  loveNote_delete = json['loveNote_delete'] == null ? null : DeleteLoveNoteLoveNoteDelete.fromJson(json['loveNote_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLoveNoteData otherTyped = other as DeleteLoveNoteData;
    return loveNote_delete == otherTyped.loveNote_delete;
    
  }
  @override
  int get hashCode => loveNote_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (loveNote_delete != null) {
      json['loveNote_delete'] = loveNote_delete!.toJson();
    }
    return json;
  }

  DeleteLoveNoteData({
    this.loveNote_delete,
  });
}

@immutable
class DeleteLoveNoteVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteLoveNoteVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLoveNoteVariables otherTyped = other as DeleteLoveNoteVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteLoveNoteVariables({
    required this.id,
  });
}


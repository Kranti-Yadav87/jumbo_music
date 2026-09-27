part of 'generated.dart';

class UnfollowUserVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  UnfollowUserVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UnfollowUserData> dataDeserializer = (dynamic json)  => UnfollowUserData.fromJson(jsonDecode(json));
  Serializer<UnfollowUserVariables> varsSerializer = (UnfollowUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UnfollowUserData, UnfollowUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UnfollowUserData, UnfollowUserVariables> ref() {
    UnfollowUserVariables vars= UnfollowUserVariables(id: id,);
    return _dataConnect.mutation("UnfollowUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UnfollowUserFollowDelete {
  final String id;
  UnfollowUserFollowDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnfollowUserFollowDelete otherTyped = other as UnfollowUserFollowDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UnfollowUserFollowDelete({
    required this.id,
  });
}

@immutable
class UnfollowUserData {
  final UnfollowUserFollowDelete? follow_delete;
  UnfollowUserData.fromJson(dynamic json):
  
  follow_delete = json['follow_delete'] == null ? null : UnfollowUserFollowDelete.fromJson(json['follow_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnfollowUserData otherTyped = other as UnfollowUserData;
    return follow_delete == otherTyped.follow_delete;
    
  }
  @override
  int get hashCode => follow_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (follow_delete != null) {
      json['follow_delete'] = follow_delete!.toJson();
    }
    return json;
  }

  UnfollowUserData({
    this.follow_delete,
  });
}

@immutable
class UnfollowUserVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UnfollowUserVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnfollowUserVariables otherTyped = other as UnfollowUserVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UnfollowUserVariables({
    required this.id,
  });
}


part of 'generated.dart';

class FollowUserVariablesBuilder {
  String followingId;

  final FirebaseDataConnect _dataConnect;
  FollowUserVariablesBuilder(this._dataConnect, {required  this.followingId,});
  Deserializer<FollowUserData> dataDeserializer = (dynamic json)  => FollowUserData.fromJson(jsonDecode(json));
  Serializer<FollowUserVariables> varsSerializer = (FollowUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<FollowUserData, FollowUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<FollowUserData, FollowUserVariables> ref() {
    FollowUserVariables vars= FollowUserVariables(followingId: followingId,);
    return _dataConnect.mutation("FollowUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FollowUserFollowInsert {
  final String id;
  FollowUserFollowInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FollowUserFollowInsert otherTyped = other as FollowUserFollowInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  FollowUserFollowInsert({
    required this.id,
  });
}

@immutable
class FollowUserData {
  final FollowUserFollowInsert follow_insert;
  FollowUserData.fromJson(dynamic json):
  
  follow_insert = FollowUserFollowInsert.fromJson(json['follow_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FollowUserData otherTyped = other as FollowUserData;
    return follow_insert == otherTyped.follow_insert;
    
  }
  @override
  int get hashCode => follow_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['follow_insert'] = follow_insert.toJson();
    return json;
  }

  FollowUserData({
    required this.follow_insert,
  });
}

@immutable
class FollowUserVariables {
  final String followingId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FollowUserVariables.fromJson(Map<String, dynamic> json):
  
  followingId = nativeFromJson<String>(json['followingId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FollowUserVariables otherTyped = other as FollowUserVariables;
    return followingId == otherTyped.followingId;
    
  }
  @override
  int get hashCode => followingId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['followingId'] = nativeToJson<String>(followingId);
    return json;
  }

  FollowUserVariables({
    required this.followingId,
  });
}


part of 'generated.dart';

class CreateUserVariablesBuilder {
  String username;
  String email;
  Optional<String> _bio = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _avatarUrl = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateUserVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }
  CreateUserVariablesBuilder avatarUrl(String? t) {
   _avatarUrl.value = t;
   return this;
  }

  CreateUserVariablesBuilder(this._dataConnect, {required  this.username,required  this.email,});
  Deserializer<CreateUserData> dataDeserializer = (dynamic json)  => CreateUserData.fromJson(jsonDecode(json));
  Serializer<CreateUserVariables> varsSerializer = (CreateUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateUserData, CreateUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateUserData, CreateUserVariables> ref() {
    CreateUserVariables vars= CreateUserVariables(username: username,email: email,bio: _bio,avatarUrl: _avatarUrl,);
    return _dataConnect.mutation("CreateUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateUserUserInsert {
  final String id;
  CreateUserUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserUserInsert otherTyped = other as CreateUserUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateUserUserInsert({
    required this.id,
  });
}

@immutable
class CreateUserData {
  final CreateUserUserInsert user_insert;
  CreateUserData.fromJson(dynamic json):
  
  user_insert = CreateUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserData otherTyped = other as CreateUserData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateUserData({
    required this.user_insert,
  });
}

@immutable
class CreateUserVariables {
  final String username;
  final String email;
  late final Optional<String>bio;
  late final Optional<String>avatarUrl;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateUserVariables.fromJson(Map<String, dynamic> json):
  
  username = nativeFromJson<String>(json['username']),
  email = nativeFromJson<String>(json['email']) {
  
  
  
  
    bio = Optional.optional(nativeFromJson, nativeToJson);
    bio.value = json['bio'] == null ? null : nativeFromJson<String>(json['bio']);
  
  
    avatarUrl = Optional.optional(nativeFromJson, nativeToJson);
    avatarUrl.value = json['avatarUrl'] == null ? null : nativeFromJson<String>(json['avatarUrl']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserVariables otherTyped = other as CreateUserVariables;
    return username == otherTyped.username && 
    email == otherTyped.email && 
    bio == otherTyped.bio && 
    avatarUrl == otherTyped.avatarUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([username.hashCode, email.hashCode, bio.hashCode, avatarUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    json['email'] = nativeToJson<String>(email);
    if(bio.state == OptionalState.set) {
      json['bio'] = bio.toJson();
    }
    if(avatarUrl.state == OptionalState.set) {
      json['avatarUrl'] = avatarUrl.toJson();
    }
    return json;
  }

  CreateUserVariables({
    required this.username,
    required this.email,
    required this.bio,
    required this.avatarUrl,
  });
}


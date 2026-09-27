part of 'generated.dart';

class ListFollowingVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListFollowingVariablesBuilder(this._dataConnect, );
  Deserializer<ListFollowingData> dataDeserializer = (dynamic json)  => ListFollowingData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListFollowingData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListFollowingData, void> ref() {
    
    return _dataConnect.query("ListFollowing", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListFollowingFollows {
  final ListFollowingFollowsFollowing following;
  ListFollowingFollows.fromJson(dynamic json):
  
  following = ListFollowingFollowsFollowing.fromJson(json['following']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFollowingFollows otherTyped = other as ListFollowingFollows;
    return following == otherTyped.following;
    
  }
  @override
  int get hashCode => following.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['following'] = following.toJson();
    return json;
  }

  ListFollowingFollows({
    required this.following,
  });
}

@immutable
class ListFollowingFollowsFollowing {
  final String username;
  ListFollowingFollowsFollowing.fromJson(dynamic json):
  
  username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFollowingFollowsFollowing otherTyped = other as ListFollowingFollowsFollowing;
    return username == otherTyped.username;
    
  }
  @override
  int get hashCode => username.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    return json;
  }

  ListFollowingFollowsFollowing({
    required this.username,
  });
}

@immutable
class ListFollowingData {
  final List<ListFollowingFollows> follows;
  ListFollowingData.fromJson(dynamic json):
  
  follows = (json['follows'] as List<dynamic>)
        .map((e) => ListFollowingFollows.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFollowingData otherTyped = other as ListFollowingData;
    return follows == otherTyped.follows;
    
  }
  @override
  int get hashCode => follows.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['follows'] = follows.map((e) => e.toJson()).toList();
    return json;
  }

  ListFollowingData({
    required this.follows,
  });
}


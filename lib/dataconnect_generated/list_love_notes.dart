part of 'generated.dart';

class ListLoveNotesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListLoveNotesVariablesBuilder(this._dataConnect, );
  Deserializer<ListLoveNotesData> dataDeserializer = (dynamic json)  => ListLoveNotesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListLoveNotesData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListLoveNotesData, void> ref() {
    
    return _dataConnect.query("ListLoveNotes", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListLoveNotesLoveNotes {
  final String message;
  final ListLoveNotesLoveNotesTrack track;
  ListLoveNotesLoveNotes.fromJson(dynamic json):
  
  message = nativeFromJson<String>(json['message']),
  track = ListLoveNotesLoveNotesTrack.fromJson(json['track']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLoveNotesLoveNotes otherTyped = other as ListLoveNotesLoveNotes;
    return message == otherTyped.message && 
    track == otherTyped.track;
    
  }
  @override
  int get hashCode => Object.hashAll([message.hashCode, track.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['message'] = nativeToJson<String>(message);
    json['track'] = track.toJson();
    return json;
  }

  ListLoveNotesLoveNotes({
    required this.message,
    required this.track,
  });
}

@immutable
class ListLoveNotesLoveNotesTrack {
  final String title;
  ListLoveNotesLoveNotesTrack.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLoveNotesLoveNotesTrack otherTyped = other as ListLoveNotesLoveNotesTrack;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  ListLoveNotesLoveNotesTrack({
    required this.title,
  });
}

@immutable
class ListLoveNotesData {
  final List<ListLoveNotesLoveNotes> loveNotes;
  ListLoveNotesData.fromJson(dynamic json):
  
  loveNotes = (json['loveNotes'] as List<dynamic>)
        .map((e) => ListLoveNotesLoveNotes.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLoveNotesData otherTyped = other as ListLoveNotesData;
    return loveNotes == otherTyped.loveNotes;
    
  }
  @override
  int get hashCode => loveNotes.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['loveNotes'] = loveNotes.map((e) => e.toJson()).toList();
    return json;
  }

  ListLoveNotesData({
    required this.loveNotes,
  });
}


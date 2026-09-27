part of 'generated.dart';

class GetLoveNoteVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetLoveNoteVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetLoveNoteData> dataDeserializer = (dynamic json)  => GetLoveNoteData.fromJson(jsonDecode(json));
  Serializer<GetLoveNoteVariables> varsSerializer = (GetLoveNoteVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetLoveNoteData, GetLoveNoteVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetLoveNoteData, GetLoveNoteVariables> ref() {
    GetLoveNoteVariables vars= GetLoveNoteVariables(id: id,);
    return _dataConnect.query("GetLoveNote", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetLoveNoteLoveNote {
  final String message;
  final GetLoveNoteLoveNoteTrack track;
  GetLoveNoteLoveNote.fromJson(dynamic json):
  
  message = nativeFromJson<String>(json['message']),
  track = GetLoveNoteLoveNoteTrack.fromJson(json['track']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLoveNoteLoveNote otherTyped = other as GetLoveNoteLoveNote;
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

  GetLoveNoteLoveNote({
    required this.message,
    required this.track,
  });
}

@immutable
class GetLoveNoteLoveNoteTrack {
  final String title;
  GetLoveNoteLoveNoteTrack.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLoveNoteLoveNoteTrack otherTyped = other as GetLoveNoteLoveNoteTrack;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  GetLoveNoteLoveNoteTrack({
    required this.title,
  });
}

@immutable
class GetLoveNoteData {
  final GetLoveNoteLoveNote? loveNote;
  GetLoveNoteData.fromJson(dynamic json):
  
  loveNote = json['loveNote'] == null ? null : GetLoveNoteLoveNote.fromJson(json['loveNote']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLoveNoteData otherTyped = other as GetLoveNoteData;
    return loveNote == otherTyped.loveNote;
    
  }
  @override
  int get hashCode => loveNote.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (loveNote != null) {
      json['loveNote'] = loveNote!.toJson();
    }
    return json;
  }

  GetLoveNoteData({
    this.loveNote,
  });
}

@immutable
class GetLoveNoteVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetLoveNoteVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLoveNoteVariables otherTyped = other as GetLoveNoteVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetLoveNoteVariables({
    required this.id,
  });
}


# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getUser();
GetUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getUser().ref();
ref.execute();

ref.subscribe(...);
```


### ListUsers
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listUsers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListUsersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listUsers();
ListUsersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listUsers().ref();
ref.execute();

ref.subscribe(...);
```


### GetPlaylist
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getPlaylist(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPlaylistData, GetPlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getPlaylist(
  id: id,
);
GetPlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getPlaylist(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListPlaylists
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listPlaylists().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListPlaylistsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listPlaylists();
ListPlaylistsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listPlaylists().ref();
ref.execute();

ref.subscribe(...);
```


### GetLoveNote
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getLoveNote(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetLoveNoteData, GetLoveNoteVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getLoveNote(
  id: id,
);
GetLoveNoteData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getLoveNote(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListLoveNotes
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listLoveNotes().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListLoveNotesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listLoveNotes();
ListLoveNotesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listLoveNotes().ref();
ref.execute();

ref.subscribe(...);
```


### ListHearts
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listHearts().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListHeartsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listHearts();
ListHeartsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listHearts().ref();
ref.execute();

ref.subscribe(...);
```


### ListFollowing
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listFollowing().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListFollowingData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listFollowing();
ListFollowingData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listFollowing().ref();
ref.execute();

ref.subscribe(...);
```


### GetTrack
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getTrack(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetTrackData, GetTrackVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getTrack(
  id: id,
);
GetTrackData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getTrack(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListTracks
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listTracks().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListTracksData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listTracks();
ListTracksData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listTracks().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUser
#### Required Arguments
```dart
String username = ...;
String email = ...;
ExampleConnector.instance.createUser(
  username: username,
  email: email,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateUser, we created `CreateUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateUserVariablesBuilder {
  ...
   CreateUserVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }
  CreateUserVariablesBuilder avatarUrl(String? t) {
   _avatarUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createUser(
  username: username,
  email: email,
)
.bio(bio)
.avatarUrl(avatarUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateUserData, CreateUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createUser(
  username: username,
  email: email,
);
CreateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String username = ...;
String email = ...;

final ref = ExampleConnector.instance.createUser(
  username: username,
  email: email,
).ref();
ref.execute();
```


### UpdateUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.updateUser().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateUser, we created `UpdateUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateUserVariablesBuilder {
  ...
 
  UpdateUserVariablesBuilder username(String? t) {
   _username.value = t;
   return this;
  }
  UpdateUserVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }
  UpdateUserVariablesBuilder avatarUrl(String? t) {
   _avatarUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.updateUser()
.username(username)
.bio(bio)
.avatarUrl(avatarUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateUserData, UpdateUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateUser();
UpdateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.updateUser().ref();
ref.execute();
```


### DeleteUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.deleteUser().execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteUser();
DeleteUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.deleteUser().ref();
ref.execute();
```


### CreatePlaylist
#### Required Arguments
```dart
String title = ...;
ExampleConnector.instance.createPlaylist(
  title: title,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreatePlaylist, we created `CreatePlaylistBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreatePlaylistVariablesBuilder {
  ...
   CreatePlaylistVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  CreatePlaylistVariablesBuilder isPublic(bool? t) {
   _isPublic.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createPlaylist(
  title: title,
)
.description(description)
.isPublic(isPublic)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreatePlaylistData, CreatePlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createPlaylist(
  title: title,
);
CreatePlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String title = ...;

final ref = ExampleConnector.instance.createPlaylist(
  title: title,
).ref();
ref.execute();
```


### UpdatePlaylist
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.updatePlaylist(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdatePlaylist, we created `UpdatePlaylistBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdatePlaylistVariablesBuilder {
  ...
   UpdatePlaylistVariablesBuilder title(String? t) {
   _title.value = t;
   return this;
  }
  UpdatePlaylistVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpdatePlaylistVariablesBuilder isPublic(bool? t) {
   _isPublic.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.updatePlaylist(
  id: id,
)
.title(title)
.description(description)
.isPublic(isPublic)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdatePlaylistData, UpdatePlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updatePlaylist(
  id: id,
);
UpdatePlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.updatePlaylist(
  id: id,
).ref();
ref.execute();
```


### DeletePlaylist
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deletePlaylist(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeletePlaylistData, DeletePlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deletePlaylist(
  id: id,
);
DeletePlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deletePlaylist(
  id: id,
).ref();
ref.execute();
```


### CreateLoveNote
#### Required Arguments
```dart
String playlistId = ...;
String trackId = ...;
String message = ...;
ExampleConnector.instance.createLoveNote(
  playlistId: playlistId,
  trackId: trackId,
  message: message,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateLoveNoteData, CreateLoveNoteVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createLoveNote(
  playlistId: playlistId,
  trackId: trackId,
  message: message,
);
CreateLoveNoteData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String playlistId = ...;
String trackId = ...;
String message = ...;

final ref = ExampleConnector.instance.createLoveNote(
  playlistId: playlistId,
  trackId: trackId,
  message: message,
).ref();
ref.execute();
```


### UpdateLoveNote
#### Required Arguments
```dart
String id = ...;
String message = ...;
ExampleConnector.instance.updateLoveNote(
  id: id,
  message: message,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateLoveNoteData, UpdateLoveNoteVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateLoveNote(
  id: id,
  message: message,
);
UpdateLoveNoteData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String message = ...;

final ref = ExampleConnector.instance.updateLoveNote(
  id: id,
  message: message,
).ref();
ref.execute();
```


### DeleteLoveNote
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteLoveNote(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteLoveNoteData, DeleteLoveNoteVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteLoveNote(
  id: id,
);
DeleteLoveNoteData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteLoveNote(
  id: id,
).ref();
ref.execute();
```


### HeartPlaylist
#### Required Arguments
```dart
String playlistId = ...;
ExampleConnector.instance.heartPlaylist(
  playlistId: playlistId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<HeartPlaylistData, HeartPlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.heartPlaylist(
  playlistId: playlistId,
);
HeartPlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String playlistId = ...;

final ref = ExampleConnector.instance.heartPlaylist(
  playlistId: playlistId,
).ref();
ref.execute();
```


### UnheartPlaylist
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.unheartPlaylist(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UnheartPlaylistData, UnheartPlaylistVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.unheartPlaylist(
  id: id,
);
UnheartPlaylistData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.unheartPlaylist(
  id: id,
).ref();
ref.execute();
```


### FollowUser
#### Required Arguments
```dart
String followingId = ...;
ExampleConnector.instance.followUser(
  followingId: followingId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<FollowUserData, FollowUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.followUser(
  followingId: followingId,
);
FollowUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String followingId = ...;

final ref = ExampleConnector.instance.followUser(
  followingId: followingId,
).ref();
ref.execute();
```


### UnfollowUser
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.unfollowUser(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UnfollowUserData, UnfollowUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.unfollowUser(
  id: id,
);
UnfollowUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.unfollowUser(
  id: id,
).ref();
ref.execute();
```


### AddTrack
#### Required Arguments
```dart
String title = ...;
String artistName = ...;
String externalUrl = ...;
ExampleConnector.instance.addTrack(
  title: title,
  artistName: artistName,
  externalUrl: externalUrl,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AddTrack, we created `AddTrackBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AddTrackVariablesBuilder {
  ...
   AddTrackVariablesBuilder albumName(String? t) {
   _albumName.value = t;
   return this;
  }
  AddTrackVariablesBuilder genre(String? t) {
   _genre.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.addTrack(
  title: title,
  artistName: artistName,
  externalUrl: externalUrl,
)
.albumName(albumName)
.genre(genre)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AddTrackData, AddTrackVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.addTrack(
  title: title,
  artistName: artistName,
  externalUrl: externalUrl,
);
AddTrackData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String title = ...;
String artistName = ...;
String externalUrl = ...;

final ref = ExampleConnector.instance.addTrack(
  title: title,
  artistName: artistName,
  externalUrl: externalUrl,
).ref();
ref.execute();
```


### UpdateTrack
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.updateTrack(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateTrack, we created `UpdateTrackBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateTrackVariablesBuilder {
  ...
   UpdateTrackVariablesBuilder genre(String? t) {
   _genre.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.updateTrack(
  id: id,
)
.genre(genre)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateTrackData, UpdateTrackVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateTrack(
  id: id,
);
UpdateTrackData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.updateTrack(
  id: id,
).ref();
ref.execute();
```


### DeleteTrack
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteTrack(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteTrackData, DeleteTrackVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteTrack(
  id: id,
);
DeleteTrackData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteTrack(
  id: id,
).ref();
ref.execute();
```


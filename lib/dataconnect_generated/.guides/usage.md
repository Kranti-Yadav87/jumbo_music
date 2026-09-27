# Basic Usage

```dart
ExampleConnector.instance.CreateUser(createUserVariables).execute();
ExampleConnector.instance.UpdateUser(updateUserVariables).execute();
ExampleConnector.instance.DeleteUser().execute();
ExampleConnector.instance.GetUser().execute();
ExampleConnector.instance.ListUsers().execute();
ExampleConnector.instance.CreatePlaylist(createPlaylistVariables).execute();
ExampleConnector.instance.UpdatePlaylist(updatePlaylistVariables).execute();
ExampleConnector.instance.DeletePlaylist(deletePlaylistVariables).execute();
ExampleConnector.instance.GetPlaylist(getPlaylistVariables).execute();
ExampleConnector.instance.ListPlaylists().execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ExampleConnector.instance.UpdateTrack({ ... })
.genre(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.


/*
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:collection';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:photo_sharing/photos_library_api/album.dart';
import 'package:photo_sharing/photos_library_api/batch_create_media_items_request.dart';
import 'package:photo_sharing/photos_library_api/batch_create_media_items_response.dart';
import 'package:photo_sharing/photos_library_api/create_album_request.dart';
import 'package:photo_sharing/photos_library_api/get_album_request.dart';
import 'package:photo_sharing/photos_library_api/join_shared_album_request.dart';
import 'package:photo_sharing/photos_library_api/join_shared_album_response.dart';
import 'package:photo_sharing/photos_library_api/list_albums_response.dart';
import 'package:photo_sharing/photos_library_api/list_shared_albums_response.dart';
import 'package:photo_sharing/photos_library_api/photos_library_api_client.dart';
import 'package:photo_sharing/photos_library_api/search_media_items_request.dart';
import 'package:photo_sharing/photos_library_api/search_media_items_response.dart';
import 'package:photo_sharing/photos_library_api/share_album_request.dart';
import 'package:photo_sharing/photos_library_api/share_album_response.dart';
import 'package:scoped_model/scoped_model.dart';

class PhotosLibraryApiModel extends Model {
  PhotosLibraryApiModel() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      _currentUser = account;

      if (_currentUser != null) {
        // Initialize the client with the new user credentials
        client = PhotosLibraryApiClient(_currentUser.authHeaders);
      } else {
        // Reset the client
        client = null;
      }
      // Reinitialize the albums
      updateAlbums();

      notifyListeners();
    });
  }

  final LinkedHashSet<Album> _albums = LinkedHashSet<Album>();
  bool hasAlbums = false;
  PhotosLibraryApiClient client;

  GoogleSignInAccount _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'profile',
    'https://www.googleapis.com/auth/photoslibrary',
    'https://www.googleapis.com/auth/photoslibrary.sharing'
  ]);
  GoogleSignInAccount get user => _currentUser;

  bool isLoggedIn() {
    return _currentUser != null;
  }

  Future<GoogleSignInAccount> signIn() => _googleSignIn.signIn();

  Future<GoogleSignInAccount> signInSilently() => _googleSignIn.signInSilently();

  Future<void> signOut() => _googleSignIn.disconnect();

  Future<Album> createAlbum(String title) async {
    final album = await client.createAlbum(CreateAlbumRequest.fromTitle(title));
    updateAlbums();
    return album;
  }

  Future<Album> getAlbum(String id) async => client.getAlbum(GetAlbumRequest.defaultOptions(id));

  Future<JoinSharedAlbumResponse> joinSharedAlbum(String shareToken) async {
    final response = await client.joinSharedAlbum(JoinSharedAlbumRequest(shareToken));
    updateAlbums();
    return response;
  }

  Future<ShareAlbumResponse> shareAlbum(String id) async {
    final response = await client.shareAlbum(ShareAlbumRequest.defaultOptions(id));
    updateAlbums();
    return response;
  }

  Future<SearchMediaItemsResponse> searchMediaItems(String albumId) async =>
      client.searchMediaItems(SearchMediaItemsRequest.albumId(albumId));

  Future<String> uploadMediaItem(File image) {
    return client.uploadMediaItem(image);
  }

  Future<BatchCreateMediaItemsResponse> createMediaItem(String uploadToken, String albumId, String description) async {
    // Construct the request with the token, albumId and description.
    final request = BatchCreateMediaItemsRequest.inAlbum(uploadToken, albumId, description);

    // Make the API call to create the media item. The response contains a
    // media item.
    final response = await client.batchCreateMediaItems(request);

    // Print and return the response.
    print(response.newMediaItemResults[0].toJson());
    return response;
  }

  UnmodifiableListView<Album> get albums => UnmodifiableListView<Album>(_albums ?? <Album>[]);

  void updateAlbums() async {
    // Reset the flag before loading new albums
    hasAlbums = false;

    // Clear all albums
    _albums.clear();

    // Skip if not signed in
    if (!isLoggedIn()) {
      return;
    }

    // Add albums from the user's Google Photos account
    // var ownedAlbums = await _loadAlbums();
    // if (ownedAlbums != null) {
    //   _albums.addAll(ownedAlbums);
    // }

    // Load albums from owned and shared albums
    final list = await Future.wait([_loadSharedAlbums(), _loadAlbums()]);

    _albums.addAll(list.expand((a) => a ?? []));

    notifyListeners();
    hasAlbums = true;
  }

  /// Load Albums into the model by retrieving the list of all albums shared
  /// with the user.
  Future<List<Album>> _loadSharedAlbums() {
    return client.listSharedAlbums().then(
      (ListSharedAlbumsResponse response) {
        return response.sharedAlbums;
      },
    );
  }

  /// Load albums into the model by retrieving the list of all albums owned
  /// by the user.
  Future<List<Album>> _loadAlbums() {
    return client.listAlbums().then(
      (ListAlbumsResponse response) {
        return response.albums;
      },
    );
  }
}

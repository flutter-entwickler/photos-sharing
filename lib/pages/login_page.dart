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

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_sharing/components/trip_app_bar.dart';
import 'package:photo_sharing/model/photos_library_api_model.dart';
import 'package:photo_sharing/pages/trip_list_page.dart';
import 'package:scoped_model/scoped_model.dart';


class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TripAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder:
          (BuildContext context, Widget child, PhotosLibraryApiModel apiModel) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/lockup_photos_horizontal.svg',
            ),
            Container(
              padding: const EdgeInsets.all(30),
              child: const Text(
                'Trips from Field Trippa will be stored as shared albums in '
                'Google Photos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: Color(0x99000000)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(15),
              ),
              onPressed: () async {
                try {
                  await apiModel.signIn() != null
                      ? _navigateToTripList(context)
                      : _showSignInError(context);
                } on Exception catch (error) {
                  print(error);
                  _showSignInError(context);
                }
              },
              child: const Text('Connect with Google Photos'),
            ),
          ],
        );
      },
    );
  }

  void _showSignInError(BuildContext context) {
    const snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: Text('Could not sign in.\n'
          'Is the Google Services file missing?'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _navigateToTripList(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => TripListPage(),
      ),
    );
  }
}

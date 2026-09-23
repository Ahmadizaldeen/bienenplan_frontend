import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/features/user/application/user_controller.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:bienenplan_frontend/features/user/data/user_repository.dart';

class _FakeUserRepository implements UserRepositoryContract {
  _FakeUserRepository({this.uploadError});

  final Exception? uploadError;

  @override
  Future<AppUser> fetchCurrentUser() async =>
      const AppUser(id: 1, name: 'Test User', email: 'test@example.com');

  @override
  Future<AppUser> uploadProfilePicture(Uint8List bytes, String filename) async {
    if (uploadError != null) throw uploadError!;
    return const AppUser(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      picture: 'uploads/users/1_profile.jpg',
    );
  }
}

void main() {
  test('uploadProfilePicture updates the current user', () async {
    final controller = UserController(userRepository: _FakeUserRepository());
    await controller.loadCurrentUser();

    final success = await controller.uploadProfilePicture(
      Uint8List.fromList([0xff, 0xd8, 0xff]),
      'profile.jpg',
    );

    expect(success, isTrue);
    expect(controller.currentUser?.picture, 'uploads/users/1_profile.jpg');
    expect(
      controller.currentProfilePictureBytes,
      Uint8List.fromList([0xff, 0xd8, 0xff]),
    );
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('uploadProfilePicture exposes errors and keeps current user', () async {
    final controller = UserController(
      userRepository: _FakeUserRepository(
        uploadError: Exception('Upload fehlgeschlagen'),
      ),
    );
    await controller.loadCurrentUser();

    final success = await controller.uploadProfilePicture(
      Uint8List.fromList([0xff, 0xd8, 0xff]),
      'profile.jpg',
    );

    expect(success, isFalse);
    expect(controller.currentUser?.name, 'Test User');
    expect(controller.errorMessage, 'Upload fehlgeschlagen');
    expect(controller.isLoading, isFalse);
  });
}

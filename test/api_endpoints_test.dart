import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/api/api_endpoints.dart';

void main() {
  group('ApiEndpoints.attachmentUrl', () {
    test('builds a backend URL for a relative upload path', () {
      expect(
        ApiEndpoints.attachmentUrl('uploads/users/profile.jpg'),
        '${ApiEndpoints.serverBaseUrl}/uploads/users/profile.jpg',
      );
    });

    test('keeps an absolute image URL unchanged', () {
      const url = 'https://example.com/profile.png';

      expect(ApiEndpoints.attachmentUrl(url), url);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Setup for all tests
/// Call this in setUpAll() of your test files
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create mock environment for tests
  dotenv.testLoad(fileInput: '''
GOOGLE_MAPS_API_KEY=test_api_key
GEMINI_API_KEY=test_gemini_key
APP_NAME=ReLink Test
APP_VERSION=1.0.0
ENVIRONMENT=test
''');
}

void main() {
  group('Test Setup', () {
    test('setupTestEnvironment should initialize without errors', () async {
      await setupTestEnvironment();
      
      // Verify that environment variables are loaded
      expect(dotenv.env['GOOGLE_MAPS_API_KEY'], equals('test_api_key'));
      expect(dotenv.env['GEMINI_API_KEY'], equals('test_gemini_key'));
      expect(dotenv.env['APP_NAME'], equals('ReLink Test'));
      expect(dotenv.env['ENVIRONMENT'], equals('test'));
    });
  });
}

/// Teardown for all tests
/// Call this in tearDownAll() of your test files
void teardownTestEnvironment() {
  // Cleanup if needed
}

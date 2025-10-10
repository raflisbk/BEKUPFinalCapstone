import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Setup for all tests
/// Call this in setUpAll() of your test files
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load test environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // If .env doesn't exist, create mock environment
    dotenv.testLoad(fileInput: '''
GOOGLE_MAPS_API_KEY=test_api_key
GEMINI_API_KEY=test_gemini_key
APP_NAME=ReLink Test
APP_VERSION=1.0.0
ENVIRONMENT=test
''');
  }
}

/// Create fake Firestore instance for testing
FakeFirebaseFirestore createFakeFirestore() {
  return FakeFirebaseFirestore();
}

/// Teardown for all tests
/// Call this in tearDownAll() of your test files
void teardownTestEnvironment() {
  // Cleanup if needed
}

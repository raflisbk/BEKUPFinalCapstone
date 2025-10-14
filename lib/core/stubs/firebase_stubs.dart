/// Firebase compatibility layer - Stub implementations to allow compilation
/// TODO: Replace with full Supabase implementations
library firebase_stubs;

/// Mock FirebaseFirestore
class FirebaseFirestore {
  static FirebaseFirestore get instance => FirebaseFirestore();
  
  CollectionReference collection(String path) => CollectionReference._();
  
  WriteBatch batch() => WriteBatch._();
}

/// Mock WriteBatch
class WriteBatch {
  WriteBatch._();
  
  void set(DocumentReference document, Map<String, dynamic> data, [SetOptions? options]) {}
  void update(DocumentReference document, Map<String, dynamic> data) {}
  void delete(DocumentReference document) {}
  
  Future<void> commit() async {}
}

/// Mock CollectionReference
class CollectionReference extends Query {
  CollectionReference._() : super._();
  
  DocumentReference doc([String? documentId]) => DocumentReference._();
  
  Future<DocumentReference> add(Map<String, dynamic> data) async => DocumentReference._();
}

/// Mock DocumentReference
class DocumentReference {
  DocumentReference._();
  
  String get id => 'mock-id';
  
  Future<DocumentSnapshot> get() async => DocumentSnapshot._();
  Stream<DocumentSnapshot> snapshots() => Stream.value(DocumentSnapshot._());
  
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  
  CollectionReference collection(String path) => CollectionReference._();
}

/// Mock DocumentSnapshot
class DocumentSnapshot {
  DocumentSnapshot._();
  
  String get id => 'mock-id';
  DocumentReference get reference => DocumentReference._();
  bool get exists => true;
  Map<String, dynamic>? data() => {
    'displayName': 'Mock User',
    'photoUrl': null,
    'latitude': 0.0,
    'longitude': 0.0,
  };
}

/// Mock QuerySnapshot
class QuerySnapshot {
  QuerySnapshot._();
  
  List<DocumentSnapshot> get docs => [];
  int get size => 0;
}

/// Mock Query
class Query {
  Query._();
  
  Query where(
    dynamic field, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isGreaterThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    dynamic arrayContainsAny,
    dynamic whereIn,
    dynamic whereNotIn,
    dynamic isNull,
  }) => Query._();
  
  Query orderBy(dynamic field, {bool descending = false}) => Query._();
  Query limit(int limit) => Query._();
  
  Future<QuerySnapshot> get() async => QuerySnapshot._();
  Stream<QuerySnapshot> snapshots() => Stream.value(QuerySnapshot._());
}

/// Mock SetOptions
class SetOptions {
  SetOptions({bool? merge});
  static SetOptions merge() => SetOptions(merge: true);
}

/// Mock FieldValue
class FieldValue {
  static FieldValue serverTimestamp() => FieldValue._();
  static FieldValue increment(num value) => FieldValue._();
  static FieldValue delete() => FieldValue._();
  static FieldValue arrayUnion(List elements) => FieldValue._();
  static FieldValue arrayRemove(List elements) => FieldValue._();
  
  FieldValue._();
}

/// Mock Timestamp
class Timestamp {
  final DateTime _dateTime;
  
  Timestamp._(this._dateTime);
  
  static Timestamp now() => Timestamp._(DateTime.now());
  static Timestamp fromDate(DateTime date) => Timestamp._(date);
  
  DateTime toDate() => _dateTime;
  
  @override
  String toString() => _dateTime.toIso8601String();
}

/// Mock FirebaseAuth
class FirebaseAuth {
  static FirebaseAuth get instance => FirebaseAuth._();
  FirebaseAuth._();
  
  User? get currentUser => null;
  Stream<User?> authStateChanges() => Stream.value(null);
  
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => UserCredential._();
  
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => UserCredential._();
  
  Future<UserCredential> signInWithCredential(AuthCredential credential) async => UserCredential._();
  
  Future<void> signOut() async {}
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

/// Mock User
class User {
  String get uid => 'mock-user-id';
  String? get email => 'mock@example.com';
  String? get displayName => 'Mock User';
  String? get photoURL => null;
  bool get emailVerified => true;
  
  Future<void> updateDisplayName(String? displayName) async {}
  Future<void> updatePhotoURL(String? photoURL) async {}
  Future<void> reload() async {}
  Future<void> delete() async {}
  Future<void> sendEmailVerification() async {}
}

/// Mock UserCredential
class UserCredential {
  UserCredential._();
  User? get user => User();
  AdditionalUserInfo? get additionalUserInfo => AdditionalUserInfo._();
}

/// Mock AdditionalUserInfo
class AdditionalUserInfo {
  AdditionalUserInfo._();
  bool get isNewUser => false;
}

/// Mock AuthException
class AuthException implements Exception {
  final String message;
  final String code;
  
  AuthException({required this.message, this.code = 'unknown'});
  
  @override
  String toString() => message;
}

/// Mock FirebaseStorage
class FirebaseStorage {
  static FirebaseStorage get instance => FirebaseStorage._();
  FirebaseStorage._();
  
  Reference ref([String? path]) => Reference._();
}

/// Mock Reference
class Reference {
  Reference._();
  
  String get fullPath => 'mock/path';
  String get name => 'mock-file';
  
  Reference child(String path) => Reference._();
  Future<TaskSnapshot> putData(dynamic data, [SettableMetadata? metadata]) async => TaskSnapshot._();
  Future<TaskSnapshot> putFile(dynamic file, [SettableMetadata? metadata]) async => TaskSnapshot._();
  Future<String> getDownloadURL() async => 'https://mock-url.com/file';
  Future<void> delete() async {}
}

/// Mock TaskSnapshot
class TaskSnapshot {
  TaskSnapshot._();
  
  TaskState get state => TaskState.success;
  Reference get ref => Reference._();
}

/// Mock TaskState
enum TaskState {
  running,
  paused,
  success,
  canceled,
  error,
}

/// Mock SettableMetadata
class SettableMetadata {
  SettableMetadata({String? contentType});
}

/// Mock FieldPath
class FieldPath {
  static String get documentId => '__name__';
}

/// Mock AggregateQuery
class AggregateQuery {
  Future<AggregateQuerySnapshot> get() async => AggregateQuerySnapshot._();
}

/// Mock AggregateQuerySnapshot
class AggregateQuerySnapshot {
  AggregateQuerySnapshot._();
  
  int? count() => 0;
}

/// Mock FirebaseMessaging
class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();
  
  Future<String?> getToken() async => 'mock-fcm-token';
  Future<void> requestPermission() async {}
  Stream<RemoteMessage> get onMessage => const Stream.empty();
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();
  
  static Future<RemoteMessage?> getInitialMessage() async => null;
}

/// Mock RemoteMessage
class RemoteMessage {
  Map<String, dynamic> get data => {};
  RemoteMessageNotification? get notification => null;
}

/// Mock RemoteMessageNotification
class RemoteMessageNotification {
  String? get title => null;
  String? get body => null;
}

/// Mock Firebase Core
class Firebase {
  static Future<void> initializeApp() async {
    // No-op for mock implementation
  }
}

/// Mock AuthCredential
class AuthCredential {
  const AuthCredential();
}

/// Mock GoogleAuthProvider
class GoogleAuthProvider {
  static AuthCredential credential({
    String? accessToken,
    String? idToken,
  }) => const AuthCredential();
}
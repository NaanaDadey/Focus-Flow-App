import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/task_repository.dart';
import '../services/timetable_repository.dart';
import '../services/course_repository.dart';
import '../services/exam_repository.dart';

enum AuthStatus { guest, authenticated, loading }

/// Central auth state. Screens read `status` to decide whether to show the
/// guest banner or full account features, and call [signIn]/[signUp]/
/// [signOut] rather than touching [AuthService] directly.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TaskRepository _taskRepo;
  final TimetableRepository _timetableRepo;
  final CourseRepository _courseRepo;
  final ExamRepository _examRepo;

  AuthProvider({
    AuthService? authService,
    TaskRepository? taskRepo,
    TimetableRepository? timetableRepo,
    CourseRepository? courseRepo,
    ExamRepository? examRepo,
  })  : _authService = authService ?? AuthService(),
        _taskRepo = taskRepo ?? TaskRepository(),
        _timetableRepo = timetableRepo ?? TimetableRepository(),
        _courseRepo = courseRepo ?? CourseRepository(),
        _examRepo = examRepo ?? ExamRepository() {
    _bootstrap();
  }

  AuthStatus status =
      AuthStatus.guest; // app opens in guest mode until we confirm otherwise
  UserProfileModel? profile;
  String? errorMessage;

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  void _bootstrap() {
    if (_authService.isLoggedIn) {
      status = AuthStatus.authenticated;
      _loadProfileAndSync();
    }
    _authService.authStateChanges.listen((_) {
      final loggedIn = _authService.isLoggedIn;
      status = loggedIn ? AuthStatus.authenticated : AuthStatus.guest;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final user =
          await _authService.signUp(email: email, password: password, fullName: fullName);
      // Push anything the user created while browsing as a guest into
      // their brand-new account so nothing is lost.
      await Future.wait([
        _taskRepo.migrateGuestDataToAccount(user.id),
        _timetableRepo.migrateGuestDataToAccount(user.id),
        _courseRepo.migrateGuestDataToAccount(user.id),
        _examRepo.migrateGuestDataToAccount(user.id),
      ]);
      await _loadProfileAndSync();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppAuthException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.guest;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.signIn(email: email, password: password);
      await Future.wait([
        _taskRepo.migrateGuestDataToAccount(user.id),
        _timetableRepo.migrateGuestDataToAccount(user.id),
        _courseRepo.migrateGuestDataToAccount(user.id),
        _examRepo.migrateGuestDataToAccount(user.id),
      ]);
      await _loadProfileAndSync();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppAuthException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.guest;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    profile = null;
    status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  Future<void> _loadProfileAndSync() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    try {
      profile = await _authService.fetchProfile(userId);
    } catch (_) {
      // Profile row may still be propagating from the sign-up trigger;
      // non-fatal, screens fall back to sensible defaults.
    }
    await Future.wait([
      _taskRepo.pullFromSupabase(),
      _timetableRepo.pullFromSupabase(),
      _courseRepo.pullFromSupabase(),
      _examRepo.pullFromSupabase(
          alertDaysBefore: profile?.examAlertDaysBefore ?? const [7, 3, 1]),
    ]);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfileModel updated) async {
    profile = await _authService.updateProfile(updated);
    notifyListeners();
  }
}

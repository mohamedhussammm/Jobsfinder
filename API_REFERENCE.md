# ShiftSphere - Controllers API Reference

## AuthController

Handles authentication, registration, and user profile management.

### Methods

#### `registerUser()`
```dart
Future<Result<UserModel>> registerUser({
  required String email,
  required String password,
  required String name,
  required String nationalIdNumber,
  required String role,
  String? phone,
  String? avatarPath,
})
```
- Creates new user account with Supabase Auth
- Creates user record in database
- Updates current user provider
- Returns: `Success<UserModel>` or `Error<AppException>`

#### `loginUser()`
```dart
Future<Result<UserModel>> loginUser({
  required String email,
  required String password,
})
```
- Authenticates user with Supabase Auth
- Fetches user record from database
- Updates current user provider
- Returns: `Success<UserModel>` or `Error<AuthException>`

#### `logout()`
```dart
Future<Result<void>> logout()
```
- Signs out user from Supabase Auth
- Clears current user provider
- Returns: `Success<void>`

#### `getCurrentUser()`
```dart
Future<Result<UserModel?>> getCurrentUser()
```
- Fetches authenticated user from database
- Returns: `Success<UserModel>` or `Success<null>`

#### `resetPassword()`
```dart
Future<Result<void>> resetPassword({required String email})
```
- Sends password reset email via Supabase
- Returns: `Success<void>`

#### `updateProfile()`
```dart
Future<Result<UserModel>> updateProfile({
  String? name,
  String? phone,
  String? avatarPath,
  bool? profileComplete,
})
```
- Updates user profile fields
- Recalculates and caches in database
- Returns: `Success<UserModel>`

---

## EventController

Handles event creation, approval, and browsing.

### Methods

#### `fetchPublishedEvents()`
```dart
Future<Result<List<EventModel>>> fetchPublishedEvents({
  int page = 0,
  String? searchQuery,
  List<String>? filters,
})
```
- Fetches published events for homepage
- Supports pagination (10 per page)
- Supports search by title
- **Only returns events with status='published'**
- Returns: `Success<List<EventModel>>`

#### `getEventById()`
```dart
Future<Result<EventModel>> getEventById(String eventId)
```
- Fetches single event by ID
- Returns: `Success<EventModel>` or `Error<NotFoundException>`

#### `createEventRequest()`
```dart
Future<Result<EventModel>> createEventRequest({
  required String companyId,
  required String title,
  required String? description,
  required LocationData? location,
  required DateTime startTime,
  required DateTime endTime,
  required int? capacity,
  required String? imagePath,
})
```
- Company creates event request
- **Always sets status='pending'**
- Validates time constraints
- Returns: `Success<EventModel>`

#### `fetchCompanyEvents()`
```dart
Future<Result<List<EventModel>>> fetchCompanyEvents(
  String companyId,
  {int page = 0}
)
```
- Fetches all events from specific company
- Pagination supported
- Returns: `Success<List<EventModel>>`

#### `fetchPendingEventRequests()`
```dart
Future<Result<List<EventModel>>> fetchPendingEventRequests({int page = 0})
```
- **Admin only** - fetches pending approval events
- Ordered by creation date (oldest first)
- Returns: `Success<List<EventModel>>`

#### `approveEvent()`
```dart
Future<Result<EventModel>> approveEvent(String eventId)
```
- **Admin only** - approves event
- Changes status to 'published'
- Returns: `Success<EventModel>`

#### `rejectEvent()`
```dart
Future<Result<EventModel>> rejectEvent(String eventId, {String? reason})
```
- **Admin only** - rejects event
- Changes status to 'cancelled'
- Returns: `Success<EventModel>`

#### `updateEvent()`
```dart
Future<Result<EventModel>> updateEvent({
  required String eventId,
  String? title,
  String? description,
  LocationData? location,
  DateTime? startTime,
  DateTime? endTime,
  int? capacity,
  String? imagePath,
  String? status,
})
```
- Updates event fields (selective)
- Can update title, description, times, capacity, image, status
- Returns: `Success<EventModel>`

#### `searchEvents()`
```dart
Future<Result<List<EventModel>>> searchEvents(String query)
```
- Searches published events by title
- Case-insensitive search
- Returns: `Success<List<EventModel>>`

---

## ApplicationController

Handles user applications to events.

### Methods

#### `applyToEvent()`
```dart
Future<Result<ApplicationModel>> applyToEvent({
  required String userId,
  required String eventId,
  String? cvPath,
  String? coverLetter,
})
```
- User applies to an event
- Prevents duplicate applications
- Sets status to 'applied'
- Returns: `Success<ApplicationModel>` or `Error<ValidationException>`

#### `withdrawApplication()`
```dart
Future<Result<void>> withdrawApplication(String applicationId)
```
- User withdraws application
- Deletes the application record
- Returns: `Success<void>`

#### `fetchUserApplications()`
```dart
Future<Result<List<ApplicationModel>>> fetchUserApplications(String userId)
```
- Fetches all applications from specific user
- Ordered by date (newest first)
- Returns: `Success<List<ApplicationModel>>`

#### `fetchEventApplications()`
```dart
Future<Result<List<ApplicationModel>>> fetchEventApplications(
  String eventId,
  {String? filterStatus}
)
```
- **Team leader view** - fetches all applications for event
- Optional filter by status
- Returns: `Success<List<ApplicationModel>>`

#### `updateApplicationStatus()`
```dart
Future<Result<ApplicationModel>> updateApplicationStatus({
  required String applicationId,
  required String newStatus,
})
```
- **Team leader only** - updates application status
- Valid statuses: 'applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected'
- Returns: `Success<ApplicationModel>`

#### `getApplicationById()`
```dart
Future<Result<ApplicationModel>> getApplicationById(String applicationId)
```
- Fetches single application details
- Returns: `Success<ApplicationModel>` or `Error<NotFoundException>`

#### `fetchApplicationsByStatus()`
```dart
Future<Result<List<ApplicationModel>>> fetchApplicationsByStatus(
  String status,
  {int page = 0, int pageSize = 10}
)
```
- Fetches applications filtered by status
- With pagination
- Returns: `Success<List<ApplicationModel>>`

#### `countApplicationsByStatus()`
```dart
Future<Result<Map<String, int>>> countApplicationsByStatus()
```
- Gets count of applications per status
- Returns: `Success<Map<String, int>>`

---

## AdminController

Handles admin-specific operations.

### Methods

#### `fetchPendingEventRequests()`
```dart
Future<Result<List<EventModel>>> fetchPendingEventRequests({int page = 0})
```
- Fetches pending event requests
- Pagination supported
- Returns: `Success<List<EventModel>>`

#### `fetchAllUsers()`
```dart
Future<Result<List<UserModel>>> fetchAllUsers({
  int page = 0,
  String? roleFilter,
  String? searchQuery,
})
```
- Fetches all users with optional filters
- Can filter by role or search by name/email
- Returns: `Success<List<UserModel>>`

#### `toggleUserStatus()`
```dart
Future<Result<UserModel>> toggleUserStatus(String userId, bool block)
```
- Blocks or unblocks user
- Sets `deleted_at` timestamp
- Logs audit action
- Returns: `Success<UserModel>`

#### `assignTeamLeaderToEvent()`
```dart
Future<Result<TeamLeaderModel>> assignTeamLeaderToEvent({
  required String userId,
  required String eventId,
})
```
- **Admin only** - assigns team leader to event
- Prevents duplicate assignments
- Logs audit action
- Returns: `Success<TeamLeaderModel>`

#### `fetchTeamLeadersForEvent()`
```dart
Future<Result<List<TeamLeaderModel>>> fetchTeamLeadersForEvent(String eventId)
```
- Fetches team leaders assigned to event
- Excludes removed assignments
- Returns: `Success<List<TeamLeaderModel>>`

#### `removeTeamLeaderFromEvent()`
```dart
Future<Result<void>> removeTeamLeaderFromEvent(String teamLeaderId)
```
- Removes team leader from event
- Sets status to 'removed'
- Logs audit action
- Returns: `Success<void>`

#### `fetchAuditLogs()`
```dart
Future<Result<List<AuditLogModel>>> fetchAuditLogs({
  int page = 0,
  String? adminUserId,
  String? targetTable,
})
```
- Fetches admin action logs
- Can filter by admin or target table
- Returns: `Success<List<AuditLogModel>>`

#### `getUserCountByRole()`
```dart
Future<Result<Map<String, int>>> getUserCountByRole()
```
- Gets user count for each role
- Returns: `Success<Map<String, int>>`

#### `getEventStatistics()`
```dart
Future<Result<Map<String, int>>> getEventStatistics()
```
- Gets event count by status
- Returns: `Success<Map<String, int>>`

---

## AnalyticsController

Provides analytics and dashboard data.

### Methods

#### `getAnalyticsKPI()`
```dart
Future<Result<AnalyticsKPI>> getAnalyticsKPI()
```
- Gets main dashboard KPIs
- Includes user counts, event stats, application counts, ratings
- Returns: `Success<AnalyticsKPI>`

#### `getMonthlyStatistics()`
```dart
Future<Result<List<MonthlyStats>>> getMonthlyStatistics({int months = 12})
```
- Gets 12 months of statistics
- Includes events created, applications, completions
- Returns: `Success<List<MonthlyStats>>`

#### `getRoleDistribution()`
```dart
Future<Result<RoleDistribution>> getRoleDistribution()
```
- Gets user count by role
- Returns: `Success<RoleDistribution>`

#### `getTopEvents()`
```dart
Future<Result<List<TopEvent>>> getTopEvents({int limit = 10})
```
- Gets top 10 events by application count
- Sorted descending
- Returns: `Success<List<TopEvent>>`

#### `getApplicationStatusDistribution()`
```dart
Future<Result<Map<String, int>>> getApplicationStatusDistribution()
```
- Gets application count by status
- Returns: `Success<Map<String, int>>`

#### `getEventStatusDistribution()`
```dart
Future<Result<Map<String, int>>> getEventStatusDistribution()
```
- Gets event count by status
- Returns: `Success<Map<String, int>>`

---

## RatingController

Handles applicant ratings.

### Methods

#### `rateApplicant()`
```dart
Future<Result<RatingModel>> rateApplicant({
  required String raterUserId,
  required String ratedUserId,
  required String eventId,
  required int score,
  String? textReview,
})
```
- **Team leader only** - rates applicant
- Score must be 1-5
- **Immutable** - cannot be updated/deleted
- Auto-updates user average rating
- Returns: `Success<RatingModel>`

#### `getUserRatings()`
```dart
Future<Result<List<RatingModel>>> getUserRatings(String userId)
```
- Fetches all ratings for a user
- Ordered by date (newest first)
- Returns: `Success<List<RatingModel>>`

#### `getRatingsGivenByUser()`
```dart
Future<Result<List<RatingModel>>> getRatingsGivenByUser(String userId)
```
- Fetches ratings given by user (team leader)
- Returns: `Success<List<RatingModel>>`

#### `getEventRatings()`
```dart
Future<Result<List<RatingModel>>> getEventRatings(String eventId)
```
- Fetches all ratings for an event
- Returns: `Success<List<RatingModel>>`

---

## TeamLeaderController

Handles team leader-specific operations.

### Methods

#### `getTeamLeaderEvents()`
```dart
Future<Result<List<EventModel>>> getTeamLeaderEvents(String userId)
```
- Gets all events assigned to team leader
- Fetches event details for each assignment
- Returns: `Success<List<EventModel>>`

#### `getTeamLeaderAssignment()`
```dart
Future<Result<TeamLeaderModel>> getTeamLeaderAssignment(String userId, String eventId)
```
- Gets specific team leader assignment details
- Returns: `Success<TeamLeaderModel>` or `Error<NotFoundException>`

#### `updateAssignmentStatus()`
```dart
Future<Result<TeamLeaderModel>> updateAssignmentStatus({
  required String assignmentId,
  required String newStatus,
})
```
- Updates assignment status
- Valid statuses: 'assigned', 'active', 'completed', 'removed'
- Returns: `Success<TeamLeaderModel>`

#### `getActiveAssignmentsCount()`
```dart
Future<Result<int>> getActiveAssignmentsCount(String userId)
```
- Counts active assignments for team leader
- Returns: `Success<int>`

#### `getCompletedAssignmentsCount()`
```dart
Future<Result<int>> getCompletedAssignmentsCount(String userId)
```
- Counts completed assignments for team leader
- Returns: `Success<int>`

---

## Error Handling

All methods return `Result<T>` which can be:

### Success Case
```dart
result.when(
  success: (data) {
    // Handle successful data
  },
  error: (error) {
    // Handle error
  }
);
```

### Exception Types
- `AppException` - Generic errors
- `AuthException` - Auth failures
- `DatabaseException` - DB errors
- `PermissionException` - RLS/permission violations
- `ValidationException` - Input validation errors
- `NotFoundException` - Resource not found
- `NetworkException` - Network issues

---

## Pagination

Standard pagination with 10 items per page:
```dart
// Page 0 = items 0-9
// Page 1 = items 10-19
// etc.

final result = await controller.method(page: 0);
```

---

## RLS Security

All operations respect Row-Level Security:
- Admins can perform admin operations
- Companies can only access their own events
- Team leaders can only see assigned events
- Users can only see their own data

The Supabase RLS policies handle this automatically.

---

**Last Updated: 2025**

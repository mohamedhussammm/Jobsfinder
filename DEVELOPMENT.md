# ShiftSphere - Development Guide

## 🎯 Quick Reference

### Architecture Layers

**Models Layer**
- Pure data classes with no business logic
- 1:1 mapping to Supabase tables
- JSON serialization via `json_serializable`
- Immutable with `copyWith()` methods

**Controller Layer**
- All business logic & Supabase access
- Uses Riverpod providers
- Returns `Result<T>` for error handling
- No Flutter widgets

**View Layer**
- Flutter UI only
- No SQL or Supabase calls
- Uses controllers via Riverpod
- Focuses on UX/animations

### Creating New Features

#### 1. Define Model
```dart
// models/example_model.dart
@JsonSerializable()
class ExampleModel {
  final String id;
  final String name;
  
  ExampleModel({required this.id, required this.name});
  
  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);
}
```

#### 2. Create Controller
```dart
// controllers/example_controller.dart
final exampleControllerProvider = Provider((ref) => ExampleController(ref));

class ExampleController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  ExampleController(this.ref);
  
  Future<Result<ExampleModel>> getExample(String id) async {
    try {
      final response = await _supabase
          .from('examples')
          .select()
          .eq('id', id)
          .single();
      
      return Success(ExampleModel.fromJson(response));
    } catch (e, st) {
      return Error(AppException(message: 'Error: $e', originalError: e, stackTrace: st));
    }
  }
}
```

#### 3. Create View
```dart
// views/example_view.dart
class ExampleView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(exampleControllerProvider);
    
    return ElevatedButton(
      onPressed: () async {
        final result = await controller.getExample('123');
        result.when(
          success: (data) => print('Got: $data'),
          error: (error) => print('Error: $error'),
        );
      },
      child: const Text('Fetch Example'),
    );
  }
}
```

### Using Providers

#### FutureProvider (for async data)
```dart
final exampleProvider = FutureProvider.autoDispose.family<ExampleModel, String>(
  (ref, id) async {
    final controller = ref.watch(exampleControllerProvider);
    final result = await controller.getExample(id);
    return result.when(
      success: (data) => data,
      error: (e) => throw e,
    );
  },
);
```

#### StateProvider (for mutable state)
```dart
final selectedExampleProvider = StateProvider<ExampleModel?>((ref) => null);
```

#### Using in Widget
```dart
final dataAsync = ref.watch(exampleProvider('123'));

dataAsync.when(
  data: (data) => Text(data.name),
  loading: () => CircularProgressIndicator(),
  error: (error, st) => Text('Error: $error'),
);
```

### Error Handling

Always return `Result<T>`:
```dart
Future<Result<List<Items>>> fetchItems() async {
  try {
    // ... logic
    return Success(items);
  } on PostgrestException catch (e) {
    return Error(DatabaseException(message: e.message, originalError: e));
  } catch (e, st) {
    return Error(AppException(message: 'Error: $e', originalError: e, stackTrace: st));
  }
}
```

### UI Components

Use `GlassContainer` for glassmorphic effects:
```dart
GlassContainer(
  blur: GlassConfig.blurMedium,
  opacity: 0.15,
  padding: const EdgeInsets.all(16),
  borderRadius: BorderRadius.circular(GlassConfig.radiusLarge),
  child: Column(
    children: [...],
  ),
)
```

### Theme Usage

Colors:
```dart
Container(color: AppColors.primary)
Container(color: AppColors.success)
Container(color: AppColors.error)
```

Typography:
```dart
Text('Title', style: AppTypography.headlineMedium)
Text('Body', style: AppTypography.bodyMedium)
Text('Caption', style: AppTypography.caption)
```

Shadows:
```dart
Container(
  decoration: BoxDecoration(boxShadow: AppShadows.card),
  child: ...
)
```

## 🔄 Common Workflows

### Fetching Published Events
```dart
final controller = ref.watch(eventControllerProvider);
final result = await controller.fetchPublishedEvents(page: 0);
```

### Creating Application
```dart
await controller.applyToEvent(
  userId: userId,
  eventId: eventId,
  cvPath: 'path/to/cv.pdf',
  coverLetter: 'Why I want...',
);
```

### Admin Approving Event
```dart
await controller.approveEvent(eventId);
```

### Team Leader Rating Applicant
```dart
await ratingController.rateApplicant(
  raterUserId: teamLeaderId,
  ratedUserId: applicantId,
  eventId: eventId,
  score: 5,
  textReview: 'Great work!',
);
```

## 🧪 Testing Tips

1. **Test with real Supabase data** - Use development credentials
2. **Test all error paths** - Network failures, permissions, etc.
3. **Test pagination** - With various page sizes
4. **Test role-based access** - Different user types

## 🚀 Performance Tips

1. Use `autoDispose` on FutureProviders to free memory
2. Use `.family` for parametric providers
3. Cache frequently accessed data with StateProvider
4. Paginate lists (10-20 items per request)
5. Use `CachedNetworkImage` for images
6. Memoize expensive computations

## 📝 Naming Conventions

- **Controllers**: `[Feature]Controller` (e.g., `EventController`)
- **Providers**: `[featureName]Provider` or `[featureName]StateProvider`
- **Models**: `[Entity]Model` (e.g., `EventModel`)
- **Views**: `[Screen/Widget]Screen` or `[Component]Widget`
- **Methods**: camelCase, action verbs (fetch, create, update, delete)

## 🔐 Security Checklist

- [ ] All tables have RLS enabled
- [ ] Models never expose sensitive data
- [ ] Controllers validate all inputs
- [ ] Error messages don't leak system details
- [ ] Tokens refreshed via Supabase Auth
- [ ] Audit logs created for admin actions

## 📚 Useful Resources

- [Supabase Docs](https://supabase.com/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

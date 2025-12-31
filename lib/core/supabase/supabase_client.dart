import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Supabase initialization provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Supabase auth provider
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

/// Initialize Supabase - call this in main.dart before runApp()
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://qxdgkioixstyigbvohmc.supabase.co',
    anonKey: 'sb_publishable_2GrDJ_wAU1ofjJI1HGy7Kw_BDhMSOWt',
  );
}

/// Supabase tables constants
class SupabaseTables {
  static const String users = 'users';
  static const String companies = 'companies';
  static const String events = 'events';
  static const String applications = 'applications';
  static const String teamLeaders = 'team_leaders';
  static const String ratings = 'ratings';
  static const String notifications = 'notifications';
  static const String auditLogs = 'audit_logs';
}

/// Common Supabase RLS error messages
class SupabaseErrors {
  static const String unauthorized = 'You do not have permission to perform this action';
  static const String notFound = 'Resource not found';
  static const String conflict = 'This resource already exists';
  static const String serverError = 'Server error occurred. Please try again later';
}

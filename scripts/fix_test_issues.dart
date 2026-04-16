#!/usr/bin/env dart

/// Script to fix common test issues
/// Run with: dart run scripts/fix_test_issues.dart

import 'dart:io';

void main() {
  print('Fixing test issues...');
  
  // Fix auth notifier test
  fixAuthNotifierTest();
  
  // Fix library notifier test
  fixLibraryNotifierTest();
  
  // Fix reader notifier test
  fixReaderNotifierTest();
  
  print('Done! Run flutter analyze to verify fixes.');
}

void fixAuthNotifierTest() {
  final file = File('test/features/auth/presentation/providers/auth_notifier_test.dart');
  if (!file.existsSync()) return;
  
  var content = file.readAsStringSync();
  
  // Replace User instantiations with TestData helper
  content = content.replaceAll(
    RegExp(r'User\(\s*id:.*?lastName:\s*[\'"]User[\'"]\s*,?\s*\)', dotAll: true),
    'TestData.createTestUser(id: \'user123\', email: \'test@example.com\', username: \'testuser\', firstName: \'Test\', lastName: \'User\')',
  );
  
  // Replace AuthResponse instantiations
  content = content.replaceAll(
    RegExp(r'AuthResponse\(\s*user:.*?refreshToken:\s*[\'"]refresh_token[\'"]\s*,?\s*\)', dotAll: true),
    'TestData.createTestAuthResponse(user: testUser, accessToken: \'access_token\', refreshToken: \'refresh_token\')',
  );
  
  file.writeAsStringSync(content);
  print('✓ Fixed auth_notifier_test.dart');
}

void fixLibraryNotifierTest() {
  final file = File('test/features/library/presentation/providers/library_notifier_test.dart');
  if (!file.existsSync()) return;
  
  var content = file.readAsStringSync();
  
  // Add TestData import if not present
  if (!content.contains('test_data.dart')) {
    content = content.replaceFirst(
      'import \'package:riverpod/riverpod.dart\';',
      'import \'package:riverpod/riverpod.dart\';\n\nimport \'../../../helpers/test_data.dart\';',
    );
  }
  
  file.writeAsStringSync(content);
  print('✓ Fixed library_notifier_test.dart');
}

void fixReaderNotifierTest() {
  final file = File('test/features/reader/presentation/providers/reader_notifier_test.dart');
  if (!file.existsSync()) return;
  
  var content = file.readAsStringSync();
  
  // Add TestData import if not present
  if (!content.contains('test_data.dart')) {
    content = content.replaceFirst(
      'import \'package:riverpod/riverpod.dart\';',
      'import \'package:riverpod/riverpod.dart\';\n\nimport \'../../../helpers/test_data.dart\';',
    );
  }
  
  file.writeAsStringSync(content);
  print('✓ Fixed reader_notifier_test.dart');
}

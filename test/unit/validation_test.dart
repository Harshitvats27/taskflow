import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/presentation/utils/validators.dart';

void main() {
  group('Validation Logic Tests', () {
    test('Login Form: email validation', () {
      expect(Validators.email(''), equals('Email is required'));
      expect(Validators.email('invalid-email'), equals('Please enter a valid email'));
      expect(Validators.email('user@example.com'), isNull);
    });

    test('Login Form: password validation', () {
      expect(Validators.password(''), equals('Password is required'));
      expect(Validators.password('12345'), equals('Password must be at least 6 characters'));
      expect(Validators.password('secure_password'), isNull);
    });

    test('Create/Edit Project: name validation', () {
      expect(Validators.projectName(''), equals('Project name is required'));
      expect(Validators.projectName('Valid Name'), isNull);
    });

    test('Create/Edit Task: title validation', () {
      expect(Validators.taskTitle(''), equals('Task title is required'));
      expect(Validators.taskTitle('Valid Task Title'), isNull);
    });
  });
}

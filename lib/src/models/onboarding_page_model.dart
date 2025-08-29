import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String imagePath; // مسار الأيقونة (مثلاً: 'assets/onboarding_icon1.png')
  final String description; // النص الوصفي لكل صفحة
  final Color backgroundColor; // لون الخلفية (يبدو وردياً خفيفاً)

  OnboardingPageModel({
    required this.imagePath,
    required this.description,
    required this.backgroundColor,
  });
}
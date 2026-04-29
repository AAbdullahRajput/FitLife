// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'mobile/mobile_profile.dart';
import 'web/web_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const WebProfile();
    return const MobileProfile();
  }
}
1234
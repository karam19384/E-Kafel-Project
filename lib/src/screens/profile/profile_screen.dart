import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/profile/profile_bloc.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      context.read<ProfileBloc>().add(LoadProfile(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return Center(child: Text(state.message));
          }
          final profile = (state is ProfileLoaded)
              ? state.profile
              : (state is ProfileUpdated)
              ? state.profile
              : null;

          if (profile == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage:
                    profile.profileImageUrl != null &&
                        profile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                child:
                    (profile.profileImageUrl == null ||
                        profile.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  profile.userRole == 'kafala_head'
                      ? 'رئيس قسم الكفالة'
                      : 'مشرف',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 32),
              _tile('المؤسسة', profile.institutionName),
              _tile('المعرف الوظيفي', profile.customId),
              _tile('البريد الإلكتروني', profile.email),
              _tile('رقم الجوال', profile.mobileNumber),
              _tile('العنوان', profile.address ?? '—'),
              _tile('المسمى الوظيفي', profile.functionalLodgment ?? '—'),
              _tile('المنطقة الوظيفية', profile.areaResponsibleFor ?? '—'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('تعديل'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  );
                  // بعد العودة، أعد التحميل
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null && mounted) {
                    context.read<ProfileBloc>().add(LoadProfile(uid));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(value, textAlign: TextAlign.end),
    );
  }
}

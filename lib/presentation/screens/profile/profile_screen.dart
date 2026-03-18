// lib/presentation/screens/profile/profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/common/app_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── تعديل الملف الشخصي ────────────────────────────────
  final _nameCtrl = TextEditingController();
  XFile? _pickedAvatar;
  bool _savingProfile = false;
  bool _profileInitialized = false;

  // ── تغيير كلمة المرور ─────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _changingPass = false;
  bool _loggingOut = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _initProfileFields(String fullName) {
    if (!_profileInitialized) {
      _nameCtrl.text = fullName;
      _profileInitialized = true;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) setState(() => _pickedAvatar = picked);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showErrorSnack('يرجى إدخال الاسم');
      return;
    }
    setState(() => _savingProfile = true);
    try {
      final profile = ref.read(authNotifierProvider).valueOrNull;
      if (profile == null) return;

      String? avatarUrl = profile.avatarUrl;

      // رفع الصورة إن تم اختيار صورة جديدة
      if (_pickedAvatar != null) {
        final storage = ref.read(storageDataSourceProvider);
        avatarUrl = await storage.uploadAvatar(
          userId: profile.id,
          image: _pickedAvatar!,
        );
        setState(() => _pickedAvatar = null);
      }

      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(fullName: name, avatarUrl: avatarUrl);

      // مسح كاش الصور لإجبار إعادة التحميل فوراً
      await CachedNetworkImage.evictFromCache(avatarUrl ?? '');

      if (mounted) _showSuccessSnack('تم تحديث الملف الشخصي بنجاح ✓');
    } catch (e) {
      if (mounted) _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _changingPass = true);

    final profile = ref.read(authNotifierProvider).valueOrNull;
    if (profile == null) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.changePasswordCustom(
        userId: profile.id,
        oldPassword: _oldPassCtrl.text,
        newPassword: _newPassCtrl.text,
      );

      // تحديث الجلسة المحفوظة بكلمة المرور الجديدة
      final saved = await SessionStorage.getSavedSession();
      if (saved != null) {
        await SessionStorage.saveSession(
          username: saved.username,
          password: _newPassCtrl.text,
          userId: profile.id,
          fullName: profile.fullName,
          role: profile.role,
        );
      }

      if (mounted) {
        setState(() => _changingPass = false);
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSuccessSnack('تم تغيير كلمة المرور بنجاح ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _changingPass = false);
        _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;

    // تهيئة حقل الاسم عند أول تحميل
    if (profile != null) _initProfileFields(profile.fullName);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // ── بطاقة معلومات المستخدم ─────────────────────
                _UserInfoCard(profile: profile, pickedAvatar: _pickedAvatar),
                const SizedBox(height: 20),

                // ── بطاقة تعديل الملف الشخصي ──────────────────
                _EditProfileCard(
                  nameCtrl: _nameCtrl,
                  pickedAvatar: _pickedAvatar,
                  isSaving: _savingProfile,
                  onPickAvatar: _pickAvatar,
                  onSave: _saveProfile,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'تغيير كلمة المرور',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 46),
                          child: Text(
                            'أدخل كلمة المرور الحالية ثم الجديدة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // كلمة المرور الحالية
                              AppTextField(
                                label: 'كلمة المرور الحالية',
                                controller: _oldPassCtrl,
                                obscureText: _obscureOld,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _ToggleVisibilityButton(
                                  obscure: _obscureOld,
                                  onToggle: () => setState(
                                    () => _obscureOld = !_obscureOld,
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'أدخل كلمة المرور الحالية'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // كلمة المرور الجديدة
                              AppTextField(
                                label: 'كلمة المرور الجديدة',
                                controller: _newPassCtrl,
                                obscureText: _obscureNew,
                                prefixIcon: const Icon(
                                  Icons.lock_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _ToggleVisibilityButton(
                                  obscure: _obscureNew,
                                  onToggle: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'أدخل كلمة المرور الجديدة';
                                  }
                                  if (v.length < 6) {
                                    return 'يجب أن تكون 6 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // تأكيد كلمة المرور
                              AppTextField(
                                label: 'تأكيد كلمة المرور الجديدة',
                                controller: _confirmPassCtrl,
                                obscureText: _obscureConfirm,
                                prefixIcon: const Icon(
                                  Icons.lock_person_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _ToggleVisibilityButton(
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'أكّد كلمة المرور';
                                  }
                                  if (v != _newPassCtrl.text) {
                                    return 'كلمتا المرور غير متطابقتين';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),

                              // زر الحفظ
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _changingPass
                                      ? null
                                      : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: _changingPass
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _changingPass
                                        ? 'جارٍ الحفظ...'
                                        : 'حفظ كلمة المرور',
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── زر تسجيل الخروج ─────────────────────────────
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _loggingOut ? null : _signOut,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تسجيل الخروج',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'ستحتاج إلى تسجيل الدخول مجدداً',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _loggingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.red,
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── بطاقة معلومات المستخدم ────────────────────────────────
class _UserInfoCard extends StatelessWidget {
  final dynamic profile;
  final XFile? pickedAvatar;
  const _UserInfoCard({required this.profile, this.pickedAvatar});

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();

    final isAdmin = profile.role == 'admin';
    final hasNetworkAvatar =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    final hasLocalPick = pickedAvatar != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // أفاتار
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: hasLocalPick
                    // عرض preview الصورة المحلية فوراً قبل الرفع
                    ? Image.network(
                        pickedAvatar!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _InitialsAvatar(name: profile.fullName),
                      )
                    : hasNetworkAvatar
                    ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _InitialsAvatar(name: profile.fullName),
                        errorWidget: (_, __, ___) =>
                            _InitialsAvatar(name: profile.fullName),
                      )
                    : _InitialsAvatar(name: profile.fullName),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? Colors.green.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAdmin
                            ? Colors.green.withOpacity(0.6)
                            : Colors.blue.withOpacity(0.6),
                      ),
                    ),
                    child: Text(
                      isAdmin ? '👑 مدير النظام' : '👤 موظف',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── أداة عرض الحروف الأولى كبديل الصورة ─────────────────
class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '؟',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── بطاقة تعديل الاسم والصورة ────────────────────────────
class _EditProfileCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final XFile? pickedAvatar;
  final bool isSaving;
  final VoidCallback onPickAvatar;
  final VoidCallback onSave;

  const _EditProfileCard({
    required this.nameCtrl,
    required this.pickedAvatar,
    required this.isSaving,
    required this.onPickAvatar,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تعديل الملف الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 46),
              child: Text(
                'غيّر اسمك أو صورتك الشخصية',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // اختيار الصورة
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: onPickAvatar,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: pickedAvatar != null
                          ? ClipOval(
                              child: Image.network(
                                pickedAvatar!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: onPickAvatar,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (pickedAvatar != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '✓ تم اختيار صورة جديدة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // حقل الاسم
            AppTextField(
              label: 'الاسم الكامل',
              controller: nameCtrl,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              validator: null,
            ),
            const SizedBox(height: 20),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── زر إخفاء/إظهار كلمة المرور ───────────────────────────
class _ToggleVisibilityButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const _ToggleVisibilityButton({
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppTheme.textSecondary,
      ),
      onPressed: onToggle,
    );
  }
}

import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';

class AdminLoginWebScreen extends StatefulWidget {
  const AdminLoginWebScreen({super.key});

  @override
  State<AdminLoginWebScreen> createState() => _AdminLoginWebScreenState();
}

class _AdminLoginWebScreenState extends State<AdminLoginWebScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = GetStorage();

  bool _obscurePassword = true;
  bool _rememberEmail = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final savedEmail = _storage.read<String>('ADMIN_REMEMBER_EMAIL');
    _emailController.text =
        (savedEmail != null && savedEmail.isNotEmpty) ? savedEmail : AdminConfig.adminEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!AdminConfig.isAdminEmail(email)) {
      setState(() {
        _errorText =
            'Email này là tài khoản khách hàng. Chỉ quản trị viên (${AdminConfig.adminEmail}) mới được phép truy cập.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      if (_rememberEmail) {
        await _storage.write('ADMIN_REMEMBER_EMAIL', email);
      } else {
        await _storage.remove('ADMIN_REMEMBER_EMAIL');
      }
      await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email, password);
      AuthenticationRepository.instance.screenRedirectAdmin();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final resetEmail = TextEditingController(text: AdminConfig.adminEmail);
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Khôi phục mật khẩu quản trị',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hệ thống sẽ gửi liên kết đặt lại mật khẩu về email quản trị viên đã đăng ký trên Firebase Auth.',
                style: TextStyle(fontSize: 13, color: AdminColors.inkSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resetEmail,
                readOnly: true,
                decoration: adminInputDecoration(
                  label: 'Email quản trị viên',
                  prefixIcon: const Icon(Iconsax.sms, size: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AuthenticationRepository.instance
                    .sendPasswordResetEmail(resetEmail.text.trim());
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không gửi được email: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.forest,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi email khôi phục'),
          ),
        ],
      ),
    );
    resetEmail.dispose();
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi liên kết đặt lại mật khẩu tới email quản trị viên.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 940;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        fontFamily: 'BeVietnamPro',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.forest,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AdminColors.canvas,
      ),
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  const Expanded(flex: 11, child: _AdminLoginShowcasePanel()),
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AdminColors.forest, AdminColors.canvas],
                    stops: [0.0, 0.34],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const _MobileBrandHeader(),
                          const SizedBox(height: 24),
                          _buildLoginCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: AdminCard(
        padding: const EdgeInsets.all(34),
        borderRadius: 20,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const AdminBadge(
                      label: 'ADMIN WEB PORTAL',
                      color: AdminColors.forest,
                      bgColor: AdminColors.sageSoft,
                      icon: Iconsax.shield_tick,
                    ),
                    if (!kIsWeb)
                      TextButton.icon(
                        onPressed: () => Get.offAll(() => const LoginScreen()),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('App khách', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đăng nhập quản trị',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Quản lý sản phẩm, đơn hàng, thương hiệu, danh mục, banner, đánh giá và thông báo cửa hàng VELORA.',
                style: TextStyle(
                  fontSize: 13,
                  color: AdminColors.inkSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              if (_errorText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AdminColors.roseBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.rose.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.warning_2, size: 18, color: AdminColors.rose),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.rose,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email quản trị';
                  if (!v.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
                decoration: adminInputDecoration(
                  label: 'Email quản trị viên',
                  hint: AdminConfig.adminEmail,
                  prefixIcon: const Icon(Iconsax.sms, size: 18, color: AdminColors.inkMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                  return null;
                },
                decoration: adminInputDecoration(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu quản trị',
                  prefixIcon: const Icon(Iconsax.lock, size: 18, color: AdminColors.inkMuted),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      size: 18,
                      color: AdminColors.inkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberEmail,
                            activeColor: AdminColors.forest,
                            onChanged: (v) => setState(() => _rememberEmail = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ghi nhớ email',
                          style: TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AdminColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Đăng nhập bảng điều khiển',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AdminColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.security_user, size: 17, color: AdminColors.forestLight),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chỉ email ${AdminConfig.adminEmail} có quyền Quản trị viên. Các email khác thuộc tài khoản Khách hàng.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AdminColors.inkSecondary,
                          height: 1.4,
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
    );
  }
}

class _AdminLoginShowcasePanel extends StatelessWidget {
  const _AdminLoginShowcasePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AdminColors.forestDark, AdminColors.forest, Color(0xFF1F4E40)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShowcaseRingsPainter())),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminColors.sage.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AdminColors.sage.withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'V',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.sage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VELORA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                          ),
                        ),
                        Text(
                          'Commerce Operating System',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Toàn bộ cửa hàng\ntrong một giao diện.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.18,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Đồng bộ trực tiếp với Firebase Firestore & Cloudinary của ứng dụng di động VELORA theo thời gian thực.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 36),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FeatureChip(icon: Iconsax.box, label: 'Sản phẩm & Biến thể'),
                    _FeatureChip(icon: Iconsax.shopping_bag, label: 'Đơn hàng & Doanh thu'),
                    _FeatureChip(icon: Iconsax.award, label: 'Thương hiệu & Danh mục'),
                    _FeatureChip(icon: Iconsax.gallery, label: 'Banner & Video Lookbook'),
                    _FeatureChip(icon: Iconsax.star, label: 'Kiểm duyệt Đánh giá'),
                    _FeatureChip(icon: Iconsax.notification, label: 'Gửi Thông báo'),
                  ],
                ),
                const Spacer(),
                const Text(
                  '© 2026 VELORA Storefront • Flutter Web Admin',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AdminColors.sage),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'VELORA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Cổng quản trị cửa hàng',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _ShowcaseRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.18),
        size.width * (0.28 + i * 0.18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

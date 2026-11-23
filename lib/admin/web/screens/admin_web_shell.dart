import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/views/banners_view.dart';
import 'package:fashion_business_app/admin/web/views/brands_view.dart';
import 'package:fashion_business_app/admin/web/views/categories_view.dart';
import 'package:fashion_business_app/admin/web/views/dashboard_view.dart';
import 'package:fashion_business_app/admin/web/views/featured_reels_view.dart';
import 'package:fashion_business_app/admin/web/views/finance_view.dart';
import 'package:fashion_business_app/admin/web/views/notifications_view.dart';
import 'package:fashion_business_app/admin/web/views/orders_view.dart';
import 'package:fashion_business_app/admin/web/views/products_view.dart';
import 'package:fashion_business_app/admin/web/views/returns_view.dart';
import 'package:fashion_business_app/admin/web/views/reviews_view.dart';
import 'package:fashion_business_app/admin/web/views/support_chat_view.dart';
import 'package:fashion_business_app/admin/web/views/users_view.dart';
import 'package:fashion_business_app/admin/web/views/vouchers_view.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/chip_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminWebShell extends StatefulWidget {
  const AdminWebShell({super.key, this.initialSection});

  final AdminSection? initialSection;

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  late final AdminWebController _controller;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<AdminWebController>()
        ? Get.find<AdminWebController>()
        : Get.put(AdminWebController());
    if (widget.initialSection != null) {
      _controller.selectSection(widget.initialSection!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1080;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.forest,
          primary: AdminColors.forest,
          brightness: Brightness.light,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AdminColors.surfaceMuted,
          selectedColor: AdminColors.forest,
          checkmarkColor: Colors.white,
          labelStyle: const TextStyle(
            color: AdminColors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: AdminColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        scaffoldBackgroundColor: AdminColors.canvas,
        dividerColor: AdminColors.border,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AdminColors.canvas,
        drawer: isDesktop
            ? null
            : Drawer(
                width: 272,
                backgroundColor: AdminColors.forestDark,
                child: _AdminSidebar(
                  controller: _controller,
                  onItemTapped: () => Navigator.of(context).pop(),
                ),
              ),
        body: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 266,
                child: _AdminSidebar(controller: _controller),
              ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    controller: _controller,
                    showMenuButton: !isDesktop,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (_controller.isLoading.value) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AdminColors.forest,
                                strokeWidth: 2.6,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Đang đồng bộ dữ liệu cửa hàng...',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AdminColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_controller.errorMessage.value.isNotEmpty &&
                          _controller.products.isEmpty &&
                          _controller.users.isEmpty) {
                        return AdminEmptyState(
                          icon: Iconsax.warning_2,
                          title: 'Không thể tải dữ liệu',
                          subtitle: _controller.errorMessage.value,
                          action: AdminPrimaryButton(
                            label: 'Thử tải lại',
                            icon: Iconsax.refresh,
                            onPressed: _controller.loadAll,
                          ),
                        );
                      }

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_controller.activeSection.value),
                          child: _buildActiveView(_controller.activeSection.value),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return AdminDashboardView(controller: _controller);
      case AdminSection.finance:
        return AdminFinanceView(controller: _controller);
      case AdminSection.orders:
        return AdminOrdersView(controller: _controller);
      case AdminSection.returns:
        return AdminReturnsView(controller: _controller);
      case AdminSection.supportChat:
        return AdminSupportChatView(controller: _controller);
      case AdminSection.products:
        return AdminProductsView(controller: _controller);
      case AdminSection.featured:
        return AdminFeaturedReelsView(controller: _controller);
      case AdminSection.vouchers:
        return AdminVouchersView(controller: _controller);
      case AdminSection.brands:
        return AdminBrandsView(controller: _controller);
      case AdminSection.categories:
        return AdminCategoriesView(controller: _controller);
      case AdminSection.banners:
        return AdminBannersView(controller: _controller);
      case AdminSection.users:
        return AdminUsersView(controller: _controller);
      case AdminSection.reviews:
        return AdminReviewsView(controller: _controller);
      case AdminSection.notifications:
        return AdminNotificationsView(controller: _controller);
    }
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.controller,
    required this.showMenuButton,
    required this.onMenuTap,
  });

  final AdminWebController controller;
  final bool showMenuButton;
  final VoidCallback onMenuTap;

  String _titleFor(AdminSection section) {
    final vi = controller.isVi.value;
    switch (section) {
      case AdminSection.dashboard:
        return vi ? 'Tổng quan cửa hàng' : 'Store Overview';
      case AdminSection.finance:
        return vi ? 'Doanh thu, Lãi / Lỗ & Thuế' : 'Revenue, P&L & Tax';
      case AdminSection.orders:
        return vi ? 'Quản lý Đơn hàng' : 'Order Management';
      case AdminSection.returns:
        return vi ? 'Quản lý Đổi trả & Bảo hành' : 'Returns & Exchanges Center';
      case AdminSection.supportChat:
        return vi ? 'Tin nhắn Khách hàng (Chat 1-1)' : 'Customer Support Chat (1-to-1)';
      case AdminSection.products:
        return vi ? 'Quản lý Sản phẩm' : 'Product & Inventory Management';
      case AdminSection.featured:
        return vi
            ? 'Quản lý Nổi bật (Video Quảng cáo & Tương tác)'
            : 'Featured Tab (Promo Videos & Engagement)';
      case AdminSection.vouchers:
        return vi ? 'Quản lý Voucher & Mã giảm giá' : 'Voucher & Coupon Management';
      case AdminSection.brands:
        return vi ? 'Quản lý Thương hiệu' : 'Brand Management';
      case AdminSection.categories:
        return vi ? 'Quản lý Danh mục' : 'Category Management';
      case AdminSection.banners:
        return vi ? 'Quản lý Banner & Chiến dịch' : 'Banners & Campaigns';
      case AdminSection.users:
        return vi ? 'Quản lý Người dùng' : 'Customer Management';
      case AdminSection.reviews:
        return vi ? 'Quản lý Đánh giá' : 'Product Reviews';
      case AdminSection.notifications:
        return vi ? 'Quản lý Thông báo' : 'Notifications & AI Insights';
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded, color: AdminColors.ink),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Obx(() => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(controller.activeSection.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink,
                      ),
                    ),
                    if (!compact)
                      Text(
                        controller.isVi.value
                            ? 'VELORA Admin • Đồng bộ Firebase Firestore'
                            : 'VELORA Admin • Live Firebase Firestore Sync',
                        style: const TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                      ),
                  ],
                )),
          ),
          // Language switcher pill (VI / EN)
          Obx(() => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CurrencyPill(
                      label: 'VI 🇻🇳',
                      selected: controller.isVi.value,
                      onTap: () => controller.setLanguage(true),
                    ),
                    _CurrencyPill(
                      label: 'EN 🇬🇧',
                      selected: !controller.isVi.value,
                      onTap: () => controller.setLanguage(false),
                    ),
                  ],
                ),
              )),
          const SizedBox(width: 8),
          // Currency switcher pill (VND / USD)
          Obx(() => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CurrencyPill(
                      label: 'VND ₫',
                      selected: controller.showVnd.value,
                      onTap: () => controller.showVnd.value = true,
                    ),
                    _CurrencyPill(
                      label: 'USD \$',
                      selected: !controller.showVnd.value,
                      onTap: () => controller.showVnd.value = false,
                    ),
                  ],
                ),
              )),
          const SizedBox(width: 10),
          Obx(() => IconButton(
                tooltip: 'Làm mới dữ liệu',
                onPressed: controller.isRefreshing.value
                    ? null
                    : () => controller.loadAll(silent: true),
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AdminColors.border),
                  ),
                ),
                icon: controller.isRefreshing.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AdminColors.forest,
                        ),
                      )
                    : const Icon(Iconsax.refresh, size: 18, color: AdminColors.ink),
              )),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AdminColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AdminColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.controller,
    this.onItemTapped,
  });

  final AdminWebController controller;
  final VoidCallback? onItemTapped;

  @override
  Widget build(BuildContext context) {
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email ?? AdminConfig.adminEmail;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AdminColors.forestDark, AdminColors.forest],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Brand header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdminColors.sage.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.sage.withValues(alpha: 0.35)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'V',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.sage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VELORA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'ADMIN WEB',
                          style: TextStyle(
                            color: AdminColors.sage,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Expanded(
              child: Obx(() {
                final active = controller.activeSection.value;
                final vi = controller.isVi.value;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  children: [
                    _SidebarGroupLabel(vi ? 'TỔNG QUAN' : 'OVERVIEW'),
                    _SidebarItem(
                      icon: Iconsax.chart_2,
                      label: vi ? 'Tổng quan' : 'Dashboard',
                      selected: active == AdminSection.dashboard,
                      onTap: () => _go(AdminSection.dashboard),
                    ),
                    _SidebarItem(
                      icon: Iconsax.money_recive,
                      label: vi ? 'Doanh thu & Lãi/Lỗ' : 'Revenue & P&L',
                      selected: active == AdminSection.finance,
                      onTap: () => _go(AdminSection.finance),
                    ),
                    _SidebarGroupLabel(vi ? 'KINH DOANH' : 'COMMERCE'),
                    _SidebarItem(
                      icon: Iconsax.shopping_bag,
                      label: vi ? 'Đơn hàng' : 'Orders',
                      badge: controller.pendingOrdersCount > 0
                          ? '${controller.pendingOrdersCount}'
                          : null,
                      selected: active == AdminSection.orders,
                      onTap: () => _go(AdminSection.orders),
                    ),
                    _SidebarItem(
                      icon: Iconsax.refresh_circle,
                      label: vi ? 'Đổi trả & Bảo hành' : 'Returns & Exchanges',
                      badge: controller.pendingReturnsCount > 0
                          ? '${controller.pendingReturnsCount}'
                          : '${controller.returnRequests.length}',
                      mutedBadge: controller.pendingReturnsCount == 0,
                      selected: active == AdminSection.returns,
                      onTap: () => _go(AdminSection.returns),
                    ),
                    _SidebarItem(
                      icon: Iconsax.message_text_1,
                      label: vi ? 'Tin nhắn Khách hàng' : 'Customer Chat (1-1)',
                      badge: controller.unreadSupportChatsCount > 0
                          ? '${controller.unreadSupportChatsCount}'
                          : '${controller.supportChats.length}',
                      mutedBadge: controller.unreadSupportChatsCount == 0,
                      selected: active == AdminSection.supportChat,
                      onTap: () => _go(AdminSection.supportChat),
                    ),
                    _SidebarItem(
                      icon: Iconsax.box,
                      label: vi ? 'Sản phẩm' : 'Products',
                      badge: '${controller.products.length}',
                      mutedBadge: true,
                      selected: active == AdminSection.products,
                      onTap: () => _go(AdminSection.products),
                    ),
                    _SidebarItem(
                      icon: Icons.auto_awesome_rounded,
                      label: vi ? 'Quản lý Nổi bật (Video)' : 'Featured & Videos',
                      badge:
                          '${controller.products.where((p) => p.isFeatured == true).length}',
                      mutedBadge: true,
                      selected: active == AdminSection.featured,
                      onTap: () => _go(AdminSection.featured),
                    ),
                    _SidebarItem(
                      icon: Iconsax.ticket_discount,
                      label: vi ? 'Voucher giảm giá' : 'Vouchers',
                      badge: '${controller.vouchers.length}',
                      mutedBadge: true,
                      selected: active == AdminSection.vouchers,
                      onTap: () => _go(AdminSection.vouchers),
                    ),
                    _SidebarGroupLabel(vi ? 'DANH MỤC & HIỂN THỊ' : 'CATALOG & DISPLAY'),
                    _SidebarItem(
                      icon: Iconsax.category,
                      label: vi ? 'Bộ sưu tập & Danh mục' : 'Athletic Collections',
                      badge: '${controller.categories.length}',
                      mutedBadge: true,
                      selected: active == AdminSection.categories,
                      onTap: () => _go(AdminSection.categories),
                    ),
                    _SidebarGroupLabel(vi ? 'KHÁCH HÀNG & TƯƠNG TÁC' : 'CUSTOMERS & ENGAGEMENT'),
                    _SidebarItem(
                      icon: Iconsax.people,
                      label: vi ? 'Người dùng' : 'Customers',
                      badge: '${controller.users.length}',
                      mutedBadge: true,
                      selected: active == AdminSection.users,
                      onTap: () => _go(AdminSection.users),
                    ),
                    _SidebarItem(
                      icon: Iconsax.star,
                      label: vi ? 'Đánh giá' : 'Reviews',
                      badge: '${controller.reviews.length}',
                      mutedBadge: true,
                      selected: active == AdminSection.reviews,
                      onTap: () => _go(AdminSection.reviews),
                    ),
                    _SidebarItem(
                      icon: Iconsax.notification_bing,
                      label: vi ? 'Thông báo' : 'Notifications',
                      selected: active == AdminSection.notifications,
                      onTap: () => _go(AdminSection.notifications),
                    ),
                  ],
                );
              }),
            ),
            // Admin account footer
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AdminColors.sage,
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color: AdminColors.forestDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quản trị viên',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currentEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showAdminConfirmDialog(
                          context,
                          title: 'Đăng xuất quản trị?',
                          message: 'Bạn có chắc chắn muốn đăng xuất khỏi cổng quản trị VELORA?',
                          confirmLabel: 'Đăng xuất',
                        );
                        if (confirm) {
                          if (Get.isRegistered<AdminWebController>()) {
                            Get.delete<AdminWebController>(force: true);
                          }
                          await AuthenticationRepository.instance.logoutAdmin();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB4BE),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      icon: const Icon(Iconsax.logout, size: 15),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  void _go(AdminSection section) {
    controller.selectSection(section);
    onItemTapped?.call();
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.mutedBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool mutedBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AdminColors.forestLight : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AdminColors.sage : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: mutedBadge
                          ? Colors.white.withValues(alpha: selected ? 0.2 : 0.1)
                          : AdminColors.sage,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedBadge ? Colors.white : AdminColors.forestDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

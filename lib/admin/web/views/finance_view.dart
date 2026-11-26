import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/views/dashboard_view.dart';
import 'package:flutter/material.dart';

/// Legacy route alias: Finance & Overview are now unified into [AdminDashboardView].
class AdminFinanceView extends StatelessWidget {
  const AdminFinanceView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardView(controller: controller);
  }
}

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'personal_info_page.dart';
import 'security_privacy_page.dart';
import '../../../payments/presentation/pages/bank_accounts_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isExporting = false;

  void _showImageOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ref.read(settingsProvider).profileImagePath != null && ref.read(settingsProvider).profileImagePath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.account_circle_rounded),
                title: Text('View Profile Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _showProfilePhotoDialog(ref.read(settingsProvider).profileImagePath!);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('Update Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text(
                'Remove Photo',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(settingsProvider.notifier).updateProfileImage('');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfilePhotoDialog(String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final name = pickedFile.name;
      final newPath = '${directory.path}/$name';
      final newFile = await File(pickedFile.path).copy(newPath);
      ref.read(settingsProvider.notifier).updateProfileImage(newFile.path);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final transactions = await ref.read(transactionRepositoryProvider).getTransactions();
      
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Transactions'];
      excel.delete('Sheet1'); // Remove default sheet

      // Add Headers
      List<String> headers = ['S.No', 'Date', 'Type', 'Category', 'Payment Method', 'Amount (₹)', 'Note'];
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());
      
      // Style Headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: ExcelColor.white,
          backgroundColorHex: ExcelColor.blue700,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Add Data
      for (int i = 0; i < transactions.length; i++) {
        final tx = transactions[i];
        final date = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}';
        final type = tx.type.toUpperCase();
        final category = tx.categoryId ?? 'General';
        final paymentMethod = tx.paymentMethod ?? 'Cash';
        final amount = tx.amount.toDouble();
        final note = tx.description ?? '';

        sheetObject.appendRow([
          TextCellValue('${i + 1}'),
          TextCellValue(date),
          TextCellValue(type),
          TextCellValue(category),
          TextCellValue(paymentMethod),
          DoubleCellValue(amount),
          TextCellValue(note),
        ]);
      }

      // Encode and Save to temp file
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/FinTrack_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File(path);
        await file.writeAsBytes(fileBytes);

        // Share it
        if (mounted) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(path)], text: 'My FinTrack Financial Report');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of FinTrack?',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(settingsProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  void _showEraseDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Erase All Data',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. All your transactions and goals will be permanently deleted.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ref
                  .read(transactionRepositoryProvider)
                  .clearAllTransactions();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data completely erased.')),
                );
              }
            },
            child: Text(
              'Erase Data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final settings = ref.watch(settingsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Dark Header Background
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1C4532), Color(0xFF2D6A4F)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).cardColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Quick Settings Action
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              'Quick Settings',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.dark_mode_rounded,
                                            ),
                                            title: Text('Dark Mode'),
                                            trailing: Switch(
                                              value: settings.isDarkMode,
                                              onChanged: (v) {
                                                ref
                                                    .read(
                                                      settingsProvider.notifier,
                                                    )
                                                    .toggleDarkMode(v);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap:
                                    settings.profileImagePath != null &&
                                        settings.profileImagePath!.isNotEmpty
                                    ? _showImageOptionsBottomSheet
                                    : _pickImage,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 3,
                                    ),
                                    image:
                                        settings.profileImagePath != null &&
                                            settings
                                                .profileImagePath!
                                                .isNotEmpty
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(settings.profileImagePath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : DecorationImage(
                                            image: NetworkImage(
                                              'https://ui-avatars.com/api/?name=${settings.userName}&background=111111&color=fff&size=200',
                                            ),
                                          ),
                                  ),
                                  child:
                                      settings.profileImagePath == null ||
                                          settings.profileImagePath!.isEmpty
                                      ? Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.userName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).cardColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.userEmail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFFC107,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFC107),
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Premium Member',
                                            style: TextStyle(
                                              color: Color(0xFFFFC107),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Stats Grid overlapping header
                Positioned(
                  top: 230,
                  left: 24,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.02),
                      ),
                    ),
                    child: metricsAsync.when(
                      data: (metrics) => Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCell(
                                  'Total Txs',
                                  metrics.transactionCount.toString(),
                                  Icons.receipt_long_rounded,
                                  const Color(0xFF2196F3),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                              Expanded(
                                child: _buildStatCell(
                                  'Total Expenses',
                                  currencyFormat.format(
                                    metrics.monthlyExpenses,
                                  ),
                                  Icons.arrow_upward_rounded,
                                  AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCell(
                                  'Total Income',
                                  currencyFormat.format(metrics.monthlyIncome),
                                  Icons.arrow_downward_rounded,
                                  AppColors.success,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                              Expanded(
                                child: _buildStatCell(
                                  'Savings Rate',
                                  metrics.monthlyIncome > 0
                                      ? '${(((metrics.monthlyIncome - metrics.monthlyExpenses) / metrics.monthlyIncome) * 100).toStringAsFixed(1)}%'
                                      : '0%',
                                  Icons.savings_rounded,
                                  const Color(0xFF673AB7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, s) => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Error')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(
              height: 170,
            ), // Increased spacing to prevent overlapping with Account Settings
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SettingsGroup(
                  title: 'Account Settings',
                  items: [
                    _SettingsItem(
                      title: 'Personal Information',
                      icon: Icons.person_rounded,
                      iconBgColor: const Color(
                        0xFF2196F3,
                      ).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF2196F3),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoPage(),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      title: 'Security & Privacy',
                      icon: Icons.security_rounded,
                      iconBgColor: const Color(
                        0xFF673AB7,
                      ).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF673AB7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityPrivacyPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: 'Financial',
                  items: [
                    _SettingsItem(
                      title: 'Goals',
                      icon: Icons.flag_rounded,
                      iconBgColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF4CAF50),
                      onTap: () => context.push('/goals'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: 'Payments',
                  items: [
                    _SettingsItem(
                      title: 'Bank Accounts',
                      icon: Icons.account_balance_rounded,
                      iconBgColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF3F51B5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BankAccountsPage(userId: settings.userEmail),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      title: 'Payment History',
                      icon: Icons.history_rounded,
                      iconBgColor: const Color(0xFF795548).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF795548),
                      onTap: () {}, // Full payment history page — coming in next iteration
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: 'App Preferences',
                  items: [
                    _SettingsItem(
                      title: 'Dark Mode',
                      icon: Icons.dark_mode_rounded,
                      iconBgColor: const Color(
                        0xFF212121,
                      ).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF212121),
                      trailing: Switch(
                        value: settings.isDarkMode,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .toggleDarkMode(v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                    _SettingsItem(
                      title: 'Notifications',
                      icon: Icons.notifications_rounded,
                      iconBgColor: const Color(
                        0xFFFF9800,
                      ).withValues(alpha: 0.1),
                      iconColor: const Color(0xFFFF9800),
                      trailing: Switch(
                        value: settings.isNotificationsEnabled,
                        onChanged: (v) {
                          ref
                              .read(settingsProvider.notifier)
                              .toggleNotifications(v);
                          if (v) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Push Notifications Enabled'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: 'Data Management',
                  items: [
                    _SettingsItem(
                      title: _isExporting ? 'Exporting...' : 'Export CSV',
                      icon: Icons.file_download_rounded,
                      iconBgColor: AppColors.success.withValues(alpha: 0.1),
                      iconColor: AppColors.success,
                      onTap: _isExporting ? null : _exportData,
                    ),
                    _SettingsItem(
                      title: 'Erase All Data',
                      icon: Icons.delete_rounded,
                      iconBgColor: AppColors.error.withValues(alpha: 0.1),
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      onTap: _showEraseDataDialog,
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    label: Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: item.titleColor ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing:
                        item.trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                    onTap: item.onTap ?? () {},
                  ),
                  if (idx < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });
}

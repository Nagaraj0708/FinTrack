import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/organic_clippers.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late final TextEditingController _nameController;
  final _locationController = TextEditingController();
  bool _isLoading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(settingsProvider).userName;
    _nameController = TextEditingController(text: initialName);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      if (_profileImage != null) {
        ref.read(settingsProvider.notifier).updateProfileImage(_profileImage!.path);
      }
      ref.read(settingsProvider.notifier).updatePersonalInfo(
        _nameController.text.trim(),
        ref.read(settingsProvider).userEmail, // preserve existing email
      );

      setState(() => _isLoading = false);
      context.go('/notifications-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/login');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background organic shape (bottom left)
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipPath(
                clipper: BottomLeftOrganicClipper(),
                child: Container(
                  width: size.width * 0.7,
                  height: size.height * 0.35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        const Color(0xFFD8EBE2), // light mint
                        const Color(0xFFD8EBE2).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Header (Back and Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface, size: 22),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/notifications-setup'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B827E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Let\'s get to know you',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This helps us personalise your experience.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Avatar Picker
                        // Avatar Picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECEA),
                                  shape: BoxShape.circle,
                                  image: _profileImage != null
                                      ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _profileImage == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: Color(0xFFAAB0AD),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A382D),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Name Input
                        _buildInputField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          suffixIcon: Icons.close_rounded,
                          onSuffixTap: () => _nameController.clear(),
                        ),
                        const SizedBox(height: 20),

                        // Location Input
                        _buildInputField(
                          controller: _locationController,
                          hintText: 'Location (e.g. Chennai, Tamil Nadu)',
                          icon: Icons.location_on_outlined,
                          suffixIcon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(height: 48),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A382D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hintText,
    required IconData icon,
    required IconData suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFAAB0AD),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSuffixTap,
            child: Icon(suffixIcon, color: const Color(0xFF7B827E), size: 20),
          ),
        ],
      ),
    );
  }
}

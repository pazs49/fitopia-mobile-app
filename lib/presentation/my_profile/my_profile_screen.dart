import 'dart:io';

import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/profile_repo.dart';
import 'package:fitopia/model/profile_summary_model.dart';
import 'package:fitopia/presentation/onboarding/onboarding1_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../resources/index_manager.dart';

class MyProfileView extends StatefulWidget {
  const MyProfileView({super.key});

  @override
  State<MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<MyProfileView> {
  final ProfileRepo _profileRepo = ProfileRepo(apiClient: ApiClient());
  ProfileSummary? _summary;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<bool> _loadSummary() async {
    try {
      final summary = await _profileRepo.getSummary();
      if (!mounted) {
        return false;
      }
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return false;
    }
  }

  Future<void> _editStartingWeight() async {
    final summary = _summary;
    if (summary == null || _isSaving) {
      return;
    }

    final controller = TextEditingController(
      text: _formatWeight(summary.initialWeight),
    );
    final weight = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change starting weight'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Starting weight (kg)',
            hintText: 'Enter 30-300 kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 30 || value > 300) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a starting weight between 30 and 300 kg.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (weight == null || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refresh your plans?'),
        content: const Text(
          'Changing your starting weight will recalculate your nutrition targets '
          'and refresh your meal and workout plans. Your current weight history '
          'will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update plans'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _profileRepo.updateStartingWeight(weight);
      final refreshed = await _loadSummary();
      if (!refreshed || !mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting weight and plans updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (_isUploadingPhoto) {
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (image == null || !mounted) {
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final response = await _profileRepo.uploadProfilePhoto(File(image.path));
      final uploadedUser = response['data'];
      if (uploadedUser is Map) {
        final storage = GetStorage();
        final existing = storage.read('user_data');
        final userData = <String, dynamic>{
          if (existing is Map) ...Map<String, dynamic>.from(existing),
          ...Map<String, dynamic>.from(uploadedUser),
        };
        await storage.write('user_data', userData);
      }
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _editName() async {
    if (_isSaving || _isUploadingPhoto) {
      return;
    }

    final userData = GetStorage().read('user_data');
    final data = userData is Map ? userData : <String, dynamic>{};
    final firstNameController =
        TextEditingController(text: data['first_name']?.toString() ?? '');
    final lastNameController =
        TextEditingController(text: data['last_name']?.toString() ?? '');

    final name = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            TextField(
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final firstName = firstNameController.text.trim();
              final lastName = lastNameController.text.trim();
              if (firstName.isEmpty || lastName.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter both your first and last name.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, [firstName, lastName]);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _profileRepo.updateName(
        firstName: name[0],
        lastName: name[1],
      );
      final updatedUser = response['data'];
      final storage = GetStorage();
      final existing = storage.read('user_data');
      final userData = <String, dynamic>{
        if (existing is Map) ...Map<String, dynamic>.from(existing),
        'first_name': name[0],
        'last_name': name[1],
        if (updatedUser is Map) ...Map<String, dynamic>.from(updatedUser),
      };
      await storage.write('user_data', userData);

      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editPhone() async {
    if (_isSaving || _isUploadingPhoto) {
      return;
    }

    final userData = GetStorage().read('user_data');
    final data = userData is Map ? userData : <String, dynamic>{};
    final controller =
        TextEditingController(text: data['phone_number']?.toString() ?? '');
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit phone number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'Enter your phone number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a phone number.')),
                );
                return;
              }
              if (value.length > 20) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number must be 20 characters or less.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (phone == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _profileRepo.updatePhone(phone);
      final updatedUser = response['data'];
      final storage = GetStorage();
      final existing = storage.read('user_data');
      final userData = <String, dynamic>{
        if (existing is Map) ...Map<String, dynamic>.from(existing),
        'phone_number': phone,
        if (updatedUser is Map) ...Map<String, dynamic>.from(updatedUser),
      };
      await storage.write('user_data', userData);

      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = GetStorage().read('user_data');
    final data = userData is Map ? userData : <String, dynamic>{};
    final firstName = _value(data, 'first_name');
    final lastName = _value(data, 'last_name');
    final fullName =
        [firstName, lastName].where((name) => name.isNotEmpty).join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.greyBoxColor,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SvgPicture.asset(
              ImageAssets.arrowBack,
              color: ColorManager.blackColor,
            ),
          ),
        ),
        title: Text(
          "My Profile",
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: AppSize.s16,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _profileAvatar(radius: 42, iconSize: 58),
                  if (_isUploadingPhoto)
                    const CircularProgressIndicator(),
                  if (!_isUploadingPhoto)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: ColorManager.secondry,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fullName.isEmpty ? 'User' : fullName,
                  textAlign: TextAlign.center,
                  style: getboldStyle(
                    color: ColorManager.blackColor,
                    fontSize: AppSize.s18,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit name',
                  onPressed: _isSaving ? null : _editName,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: ColorManager.secondry,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _infoTile(Icons.email_outlined, 'Email', _value(data, 'email')),
            _infoTile(
              Icons.person_outline,
              'Username',
              _value(data, 'username'),
            ),
            _infoTile(
              Icons.phone_outlined,
              'Phone',
              _value(data, 'phone_number'),
              onEdit: _isSaving ? null : _editPhone,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_summary != null) ...[
              _infoTile(
                Icons.monitor_weight_outlined,
                'Starting weight',
                '${_formatWeight(_summary!.initialWeight)} kg',
              ),
              _infoTile(
                Icons.flag_outlined,
                'Goal weight',
                '${_formatWeight(_summary!.goalWeight)} kg',
              ),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _editStartingWeight,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                label: Text(_isSaving
                    ? 'Updating plans...'
                    : 'Correct starting weight'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const Onboarding1View(isEditing: true),
                          ),
                        );
                        if (updated == true && mounted) {
                          await _loadSummary();
                        }

                      },
                icon: const Icon(Icons.tune),
                label: const Text('Edit goals and questionnaire'),
              ),
              const SizedBox(height: 8),
              const Text(
                'To record your current weight, add a new measurement in Analytics.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileAvatar({required double radius, required double iconSize}) {
    final userData = GetStorage().read('user_data');
    final imageUrl = resolveProfileImageUrl(
      userData is Map ? userData['profile_image'] : null,
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: ColorManager.greylightColor,
      child: SvgPicture.asset(
        ImageAssets.userCircleIcon,
        color: ColorManager.greyColor,
        width: iconSize,
        height: iconSize,
      ),
    );
  }

  static String _value(Map data, String key) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? 'Not provided' : value;
  }

  static String _formatWeight(double value) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: ColorManager.secondry),
        title: Text(label),
        subtitle: Text(value),
        trailing: onEdit == null
            ? null
            : IconButton(
                tooltip: 'Edit $label',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: ColorManager.secondry,
              ),
      ),
    );
  }
}

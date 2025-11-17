import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/providers/theme_mode_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _photoUrlController;
  File? _pickedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _photoUrlController = TextEditingController(text: user?.photoURL ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final name = _nameController.text.trim();
    final photo = _photoUrlController.text.trim();

    try {
      if (name.isNotEmpty && name != user.displayName) {
        await user.updateDisplayName(name);
      }
      if (photo.isNotEmpty && photo != user.photoURL) {
        await user.updatePhotoURL(photo);
      }
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source);
      if (xfile == null) return;

      // Crop the image to a square for consistency
      final cropped = await ImageCropper().cropImage(
        sourcePath: xfile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop avatar', lockAspectRatio: true),
          IOSUiSettings(title: 'Crop avatar', aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return;

      // Compress the cropped image to reduce upload size
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/avatar_${user.uid}.jpg';
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        cropped.path,
        minWidth: 600,
        minHeight: 600,
        quality: 85,
      );
      if (compressedBytes == null) return;
      final compressedFile = await File(targetPath).writeAsBytes(compressedBytes);

      setState(() {
        _pickedImage = compressedFile;
      });

      // Use a fixed filename so the user's avatar overwrites previous uploads
      final storageRef = FirebaseStorage.instance.ref().child('user_photos/${user.uid}/avatar.jpg');

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final uploadTask = storageRef.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes;
        final progress = total > 0 ? (event.bytesTransferred / total) : 0.0;
        setState(() {
          _uploadProgress = progress.clamp(0.0, 1.0);
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's photo URL in Firebase Auth
      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      // Update local controller and UI
      _photoUrlController.text = downloadUrl;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo uploaded')));
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      await _pickAndUploadImage(choice);
    }
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This action is irreversible. You may need to reauthenticate before deletion.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await user.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (user?.photoURL != null && user!.photoURL!.isNotEmpty
                                ? NetworkImage(user.photoURL!) as ImageProvider
                                : const AssetImage('assets/icons/avatar_placeholder.png')),
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          onPressed: _showImageSourceActionSheet,
                          tooltip: 'Change photo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'No name', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(user?.email ?? 'No email', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isUploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _uploadProgress),
              ],

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display name', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Your display name'),
                    ),
                    const SizedBox(height: 16),

                    Text('Profile photo (paste image URL)', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(hintText: 'https://...'),
                    ),
                    const SizedBox(height: 24),

                    Text('App theme', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Use a SegmentedButton (Material 3) for theme selection
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: <ThemeMode>{themeMode},
                      onSelectionChanged: (newSelection) {
                        final selected = newSelection.first;
                        ref.read(themeModeProvider.notifier).setThemeMode(selected);
                      },
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                      onPressed: () async {
                        await ref.read(firebaseAuthProvider).signOut();
                      },
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: _deleteAccount,
                      child: const Text('Delete account'),
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

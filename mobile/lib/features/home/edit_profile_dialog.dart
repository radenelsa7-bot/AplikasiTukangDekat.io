import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage_service.dart';
import '../auth/auth_controller.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  XFile? _picked;
  Uint8List? _pickedBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    _nameCtrl.text = authState.userFullName ?? '';
    _phoneCtrl.text = authState.userPhoneNumber ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      // Read bytes so we can support web uploads (ImagePicker on web doesn't provide a file path)
      final bytes = await file.readAsBytes();
      setState(() {
        _picked = file;
        _pickedBytes = bytes;
      });
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isSaving = true);
    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .deleteProfilePhoto();
      if (!mounted) return;
      if (success) {
        setState(() {
          _picked = null;
          _pickedBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil dihapus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus foto profil')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus foto profil')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      MultipartFile? mf;
      if (_picked != null) {
        if (_pickedBytes != null) {
          mf = MultipartFile.fromBytes(_pickedBytes!, filename: _picked!.name);
        } else {
          // Fallback for platforms where path is available (mobile)
          mf = await MultipartFile.fromFile(
            _picked!.path,
            filename: _picked!.name,
          );
        }
      }
      final api = ref.read(apiServiceProvider);
      final result = await api.updateProfile(
        fullName: _nameCtrl.text.isEmpty ? null : _nameCtrl.text,
        phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        photoFile: mf,
      );

      // Update auth state and storage with new profile data
      if (result['user'] is Map<String, dynamic>) {
        final user = result['user'] as Map<String, dynamic>;
        final fullName = user['full_name'] as String?;
        final phoneNumber = user['phone_number'] as String?;
        final profilePhotoPath = user['profile_photo_path'] as String?;

        // Update storage
        await ref
            .read(authStorageProvider)
            .saveUserData(
              userId: user['id'] ?? 0,
              userRole: user['role'] ?? 'CUSTOMER',
              userEmail: user['email'] ?? '',
              fullName: fullName,
              phoneNumber: phoneNumber,
              profilePhotoPath: profilePhotoPath,
            );

        // Update auth controller state
        ref
            .read(authControllerProvider.notifier)
            .updateState(
              (current) => current.copyWith(
                userFullName: fullName,
                userPhoneNumber: phoneNumber,
                userProfilePhotoPath: profilePhotoPath,
              ),
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Gagal menyimpan profil';
      try {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null) {
          message = e.message!;
        }
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan profil')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hasCurrentPhoto =
        authState.userProfilePhotoPath != null ||
        _picked != null ||
        _pickedBytes != null;
    final ImageProvider<Object>? backgroundImage = _pickedBytes != null
        ? MemoryImage(_pickedBytes!)
        : (authState.userProfilePhotoPath != null
              ? NetworkImage(
                  '${Uri.base.origin}/storage/${authState.userProfilePhotoPath}',
                )
              : null);

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 36,
                backgroundImage: backgroundImage,
                child: backgroundImage == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'No HP'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        if (hasCurrentPhoto)
          TextButton(
            onPressed: _isSaving ? null : _deletePhoto,
            child: const Text('Hapus Foto'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

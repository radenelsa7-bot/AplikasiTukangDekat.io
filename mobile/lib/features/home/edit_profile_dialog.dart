import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
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
      final bytes = await file.readAsBytes();
      if (!mounted) return;
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      MultipartFile? mf;
      if (_picked != null) {
        final fileName = _picked!.name;
        final mimeType = fileName.toLowerCase().endsWith('.png')
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');
        if (_pickedBytes != null) {
          mf = MultipartFile.fromBytes(
            _pickedBytes!,
            filename: fileName,
            contentType: mimeType,
          );
        } else {
          mf = await MultipartFile.fromFile(
            _picked!.path,
            filename: fileName,
            contentType: mimeType,
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
        if (data is Map) {
          if (data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final msgs = <String>[];
            errors.forEach((key, val) {
              if (val is List && val.isNotEmpty) {
                msgs.add(val.first.toString());
              }
            });
            if (msgs.isNotEmpty) message = msgs.join(', ');
          } else if (data['message'] != null) {
            message = data['message'].toString();
          }
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
      if (mounted) setState(() => _isSaving = false);
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
                backgroundColor: Colors.grey[300],
                backgroundImage: _pickedBytes != null
                    ? MemoryImage(_pickedBytes!) as ImageProvider
                    : (authState.userProfilePhotoPath != null && authState.userProfilePhotoPath!.isNotEmpty
                        ? NetworkImage(
                            '${ApiConfig.baseUrl}/api/storage/${authState.userProfilePhotoPath}',
                          )
                        : null),
                child: _pickedBytes == null &&
                        (authState.userProfilePhotoPath == null ||
                            authState.userProfilePhotoPath!.isEmpty)
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                hintText: 'Min. 7 digit',
              ),
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

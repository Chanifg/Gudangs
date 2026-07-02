import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  
  String? _tempImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.profileName);
    _companyController = TextEditingController(text: settings.profileCompanyName);
    _phoneController = TextEditingController(text: settings.profilePhone);
    _tempImagePath = settings.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Copy picked file to permanent app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          _tempImagePath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Reset/Delete avatar photo
  void _resetToDefault() {
    setState(() {
      _tempImagePath = null;
    });
  }

  // Set avatar preset color index
  void _setPresetColor(int index) {
    setState(() {
      _tempImagePath = 'preset:$index';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(settingsProvider.notifier).clearMessage();
    
    final success = await ref.read(settingsProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          companyName: _companyController.text.trim(),
          phone: _phoneController.text.trim(),
          profileImagePath: _tempImagePath,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Color(0xFF006E2F),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(settingsProvider).errorMessage ?? 'Gagal menyimpan profil';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  // Premium Widget for rendering Avatar preview
  Widget _buildAvatarPreview(ColorScheme colorScheme) {
    final nameLetter = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'A';

    if (_tempImagePath != null && _tempImagePath!.isNotEmpty) {
      if (_tempImagePath!.startsWith('preset:')) {
        final idx = int.tryParse(_tempImagePath!.split(':').last) ?? 0;
        return CircleAvatar(
          radius: 50,
          backgroundColor: _getPresetBgColor(idx),
          child: Text(
            nameLetter,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      } else {
        final file = File(_tempImagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(file),
          );
        }
      }
    }

    // Default Avatar
    return CircleAvatar(
      radius: 50,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: 54, color: colorScheme.primary),
    );
  }

  Color _getPresetBgColor(int index) {
    final colors = [
      const Color(0xFF006E2F), // Green
      const Color(0xFF0B1C30), // Navy
      const Color(0xFF1E3A8A), // Blue
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil Admin'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                
                // Avatar Preview
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _buildAvatarPreview(colorScheme),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF006E2F),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: () {
                          // Show options sheet
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_outlined),
                                    title: const Text('Pilih dari Galeri'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImageFromGallery();
                                    },
                                  ),
                                  if (_tempImagePath != null)
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                                      title: const Text('Hapus Foto Profil', style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _resetToDefault();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Colorful Presets Selectors
                const Text(
                  'Atau gunakan warna inisial:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: 8,
                    itemBuilder: (context, idx) {
                      final color = _getPresetBgColor(idx);
                      final isSelected = _tempImagePath == 'preset:$idx';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: InkWell(
                          onTap: () => _setPresetColor(idx),
                          borderRadius: BorderRadius.circular(16),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: color,
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 28),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  onChanged: (val) => setState(() {}), // Force rebuild to update initial avatar letter dynamically
                  decoration: const InputDecoration(
                    labelText: 'Nama Pengguna (Admin)',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Masukkan nama Anda...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Company Name Input
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perusahaan / Gudang',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                    hintText: 'Masukkan nama Gudang/Perusahaan...',
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Contoh: 081234567890',
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006E2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveProfile,
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

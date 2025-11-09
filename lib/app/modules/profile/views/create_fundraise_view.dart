import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../post/controllers/post_controller.dart';

class CreateFundraiseView extends StatefulWidget {
  const CreateFundraiseView({Key? key}) : super(key: key);

  @override
  State<CreateFundraiseView> createState() => _CreateFundraiseViewState();
}

class _CreateFundraiseViewState extends State<CreateFundraiseView> {
  late final PostController _postController;
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _postController = Get.put(PostController());
    _postController.setType('fundraise');
  }

  @override
  void dispose() {
    _postController.resetType();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xff4B164C),
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Fundraise',
          style: TextStyle(
            color: Color(0xff4B164C),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _postController.createPost(),
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Color(0xff4B164C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description Field
            _buildSectionTitle('Description'),
            _buildDescriptionField(),
            const SizedBox(height: 24),

            // Amount Needed Field
            _buildSectionTitle('Amount Needed'),
            _buildAmountField(),
            const SizedBox(height: 24),

            // Deadline Field (Optional)
            _buildSectionTitle('Deadline (optional)'),
            _buildDeadlineField(),
            const SizedBox(height: 24),

            // Media Section
            _buildSectionTitle('Photos & Videos'),
            _buildMediaSection(),
            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xff4B164C),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _postController.descriptionController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Describe your fundraising campaign...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _postController.amountController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Enter amount needed (optional)',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixText: '\$ ',
        ),
      ),
    );
  }

  Widget _buildDeadlineField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _postController.deadlineController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Select deadline date',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xff4B164C)),
            onPressed: _selectDeadlineDate,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // Media Grid
        Obx(() {
          if (_postController.selectedMedia.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_postController.selectedMedia.length}/${PostController.MAX_MEDIA_FILES}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _postController.selectedMedia.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final file = _postController.selectedMedia[index];
                      final isVideo = _isVideoFile(file);
                      return _buildMediaThumbnail(file, isVideo, index);
                    },
                  ),
                ),
              ],
            ),
          );
        }),

        // Add Media Buttons
        if (_postController.canAddMoreMedia)
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_camera,
                  label: 'Camera',
                  onTap: _capturePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff4B164C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff4B164C).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xff4B164C), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff4B164C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(File file, bool isVideo, int index) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? _buildVideoThumbnail(file)
                : Image.file(
                    file,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.videocam, color: Colors.grey),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (isVideo)
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(File videoFile) {
    return FutureBuilder<String?>(
      future: _getVideoThumbnail(videoFile.path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        }
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.videocam, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _postController.isLoading.value ? null : () => _postController.createPost(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4B164C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _postController.isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Fundraising Campaign',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ));
  }

  bool _isVideoFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 100,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      log('Error generating video thumbnail: $e');
      return null;
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        _postController.selectedMedia.add(File(image.path));
      }
    } catch (e) {
      log('Error capturing photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> media = await _imagePicker.pickMultipleMedia();
      for (final file in media) {
        if (_postController.canAddMoreMedia) {
          _postController.selectedMedia.add(File(file.path));
        }
      }
    } catch (e) {
      log('Error picking media: $e');
    }
  }

  void _removeMedia(int index) {
    _postController.selectedMedia.removeAt(index);
  }

  Future<void> _selectDeadlineDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Format date as YYYY-MM-DD for proper backend parsing
      _postController.deadlineController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
}
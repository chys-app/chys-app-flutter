import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Fundraise',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          // Safety check for controller and selectedMedia
          if (_postController.selectedMedia.isEmpty) {
            return _buildEmptyState();
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Media preview section - flexible height
                  Flexible(
                    flex: 3,
                    child: _buildMediaPreview(),
                  ),
                  
                  // Fundraiser input section
                  Flexible(
                    flex: 2,
                    child: _buildFundraiserSection(),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No media selected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos or videos to continue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showMediaPicker(),
            icon: const Icon(Icons.add),
            label: const Text('Add Media'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: PageView.builder(
        controller: PageController(),
        itemCount: _postController.selectedMedia.length,
        itemBuilder: (context, index) {
          final mediaFile = _postController.selectedMedia[index];
          if (mediaFile.path.toLowerCase().endsWith('.mp4') ||
              mediaFile.path.toLowerCase().endsWith('.mov') ||
              mediaFile.path.toLowerCase().endsWith('.avi')) {
            return _buildVideoPreview(mediaFile);
          } else {
            return _buildImagePreview(mediaFile);
          }
        },
      ),
    );
  }

  Widget _buildImagePreview(File imageFile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.file(
        imageFile,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideoPreview(File videoFile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white.withOpacity(0.7),
              size: 80,
            ),
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundraiserSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: _postController.descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Describe your fundraiser...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Amount input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: _postController.amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Amount needed (\$)',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Deadline input
            GestureDetector(
              onTap: _selectDeadlineDate,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: TextField(
                  controller: _postController.deadlineController,
                  readOnly: true,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Deadline (optional)',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Submit button
            Obx(() => ElevatedButton(
              onPressed: _postController.isLoading.value ? null : () {
                _postController.createPost();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _postController.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Fundraiser',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )),
          ],
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Add Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Get.back();
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles != null) {
      for (var file in pickedFiles) {
        if (_postController.selectedMedia.length < PostController.MAX_MEDIA_FILES) {
          _postController.selectedMedia.add(File(file.path));
        }
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null && _postController.selectedMedia.length < PostController.MAX_MEDIA_FILES) {
      _postController.selectedMedia.add(File(pickedFile.path));
    }
  }

  Future<void> _selectDeadlineDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _postController.deadlineController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
}
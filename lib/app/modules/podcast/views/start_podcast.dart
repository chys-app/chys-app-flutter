import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../signup/widgets/custom_text_field.dart';

class StartPodcastScreen extends StatelessWidget {
  StartPodcastScreen({super.key});

  final CreatePodCastController controller = Get.put(CreatePodCastController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5568), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Podcast Editor',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFBFC), Color(0xFFF7FAFC)],
          ),
        ),
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: 24),
                
                // Podcast Frame Preview
                _buildPreviewSection(),
                const SizedBox(height: 24),
                
                // Template Selection
                Obx(() => controller.selectedImage.value != null ||
                        controller.networkImageUrl.value.isNotEmpty
                    ? _buildTemplateSection()
                    : const SizedBox.shrink()),
                
                // Customization Sections
                _buildCustomizationSections(),
                const SizedBox(height: 24),
                
                // Proof Images Section
                _buildProofImagesSection(),
                const SizedBox(height: 24),
                
                // Podcast Details Section
                Builder(
                  builder: (context) => _buildPodcastDetailsSection(context),
                ),
                const SizedBox(height: 32),
                
                // Schedule Button
                _buildScheduleButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Your Podcast",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Design your podcast frame and add details to start your fundraising journey! 🎙️✨",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Podcast Frame Preview", Icons.photo_library),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A202C).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: RepaintBoundary(
              key: controller.previewKey,
              child: Obx(() => InkWell(
                    onTap: controller.pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: Get.height * 0.32,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            controller.templateColors[controller.selectedTemplate.value],
                            controller.templateColors[controller.selectedTemplate.value].withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: controller.templateColors[controller.selectedTemplate.value].withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background Pattern
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: RadialGradient(
                                  center: Alignment.topRight,
                                  radius: 1.0,
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Main Image Area - Better proportions
                          Positioned(
                            top: 50,
                            left: 16,
                            right: 16,
                            bottom: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: controller.selectedImage.value != null
                                    ? Image.file(
                                        controller.selectedImage.value!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : controller.networkImageUrl.value.isNotEmpty
                                        ? Image.network(
                                            controller.networkImageUrl.value,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildBetterPlaceholder();
                                            },
                                          )
                                        : _buildBetterPlaceholder(),
                              ),
                            ),
                          ),
                          
                          // Text Overlays - Cleaner design
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              children: [
                                // Heading 1 - Clean glass effect
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    controller.heading1Text.value,
                                    style: GoogleFonts.getFont(
                                      controller.heading1Font.value,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: controller.heading1Color.value,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Heading 2 - Clean glass effect
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    controller.heading2Text.value,
                                    style: GoogleFonts.getFont(
                                      controller.heading2Font.value,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: controller.heading2Color.value,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Banner Line - Clean design
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: controller.bannerBackgroundColor.value,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                controller.bannerLineText.value,
                                style: GoogleFonts.getFont(
                                  controller.bannerLineFont.value,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: controller.bannerLineColor.value,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          // Simple corner accents
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBetterPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add image',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF1D4ED8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to add premium image',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'High quality recommended',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Select Frame Style", Icons.palette),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A202C).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.templateColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = controller.templateColors[index];
                final label = _getColorLabel(index);
                return _buildTemplateOption(index, color, label);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationSections() {
    return Builder(
      builder: (context) => Column(
        children: [
          // Heading 1 Customization
          _buildCustomizationCard(
            "Heading 1",
            Icons.title,
            Column(
              children: [
                CustomTextField(
                  label: 'Heading 1 Text',
                  controller: TextEditingController(text: controller.heading1Text.value),
                  onChanged: (value) => controller.heading1Text.value = value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFontSelector(
                        "Font",
                        controller.heading1Font.value,
                        (font) => controller.heading1Font.value = font,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => Expanded(
                          child: _buildColorSelector(
                            context,
                            "Color",
                            controller.heading1Color.value,
                            (color) => controller.heading1Color.value = color,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Heading 2 Customization
          _buildCustomizationCard(
            "Heading 2",
            Icons.text_fields,
            Column(
              children: [
                CustomTextField(
                  label: 'Heading 2 Text',
                  controller: TextEditingController(text: controller.heading2Text.value),
                  onChanged: (value) => controller.heading2Text.value = value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFontSelector(
                        "Font",
                        controller.heading2Font.value,
                        (font) => controller.heading2Font.value = font,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => Expanded(
                          child: _buildColorSelector(
                            context,
                            "Color",
                            controller.heading2Color.value,
                            (color) => controller.heading2Color.value = color,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Banner Line Customization
          _buildCustomizationCard(
            "Banner Line",
            Icons.format_align_center,
            Column(
              children: [
                CustomTextField(
                  label: 'Banner Line Text',
                  controller: TextEditingController(text: controller.bannerLineText.value),
                  onChanged: (value) => controller.bannerLineText.value = value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFontSelector(
                        "Font",
                        controller.bannerLineFont.value,
                        (font) => controller.bannerLineFont.value = font,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => Expanded(
                          child: _buildColorSelector(
                            context,
                            "Text Color",
                            controller.bannerLineColor.value,
                            (color) => controller.bannerLineColor.value = color,
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildColorSelector(
                  context,
                  "Banner Background Color",
                  controller.bannerBackgroundColor.value,
                  (color) => controller.bannerBackgroundColor.value = color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Proof Images (max 5)", Icons.photo_camera),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A202C).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.proofImages.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        if (index < controller.proofImages.length) {
                          final file = controller.proofImages[index];
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    file,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => controller.removeProofImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Add button
                          return GestureDetector(
                            onTap: controller.proofImages.length < CreatePodCastController.maxProofImages
                                ? controller.pickProofImage
                                : null,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD1D5DB), width: 2, style: BorderStyle.solid),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                size: 32,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (controller.proofImages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Add at least one proof image.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )),
        ),
      ],
    );
  }

  Widget _buildPodcastDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Podcast Details", Icons.info_outline),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A202C).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              CustomTextField(
                label: 'Title',
                controller: controller.titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter podcast title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Total amount for fundraising',
                controller: controller.totalAmountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total amount you want to raise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Description',
                controller: controller.descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Obx(() => GestureDetector(
                    onTap: () => controller.pickScheduleDate(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        label: 'Schedule At',
                        controller: TextEditingController(
                          text: controller.scheduledAt.value == null
                              ? ''
                              : '${controller.scheduledAt.value!.toLocal()}'.split('.')[0],
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 20),
                        ),
                        readOnly: true,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0095F6), Color(0xFF0066CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0095F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.createPodCast,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Schedule Podcast',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationCard(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A202C).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTemplateOption(int index, Color color, String label) {
    final controller = Get.find<CreatePodCastController>();
    return Obx(() => GestureDetector(
          onTap: () {
            controller.selectedTemplate.value = index;
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.selectedTemplate.value == index
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
                width: controller.selectedTemplate.value == index ? 3 : 1,
              ),
              boxShadow: controller.selectedTemplate.value == index
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Image Preview
                if (controller.selectedImage.value != null ||
                    controller.networkImageUrl.value.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: controller.selectedImage.value != null
                            ? Image.file(
                                controller.selectedImage.value!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                controller.networkImageUrl.value,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF9CA3AF),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                // Label
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildFontSelector(String label, String currentFont, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF9FAFB),
          ),
          child: DropdownButton<String>(
            value: currentFont,
            isExpanded: true,
            underline: const SizedBox(),
            items: controller.availableFonts.map((font) {
              return DropdownMenuItem(
                value: font,
                child: Text(
                  font,
                  style: GoogleFonts.getFont(font, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (font) {
              if (font != null) onChanged(font);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(BuildContext context, String label, Color currentColor, Function(Color) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => controller.showColorPicker(context, currentColor, onChanged),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Tap to change',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getColorLabel(int index) {
    const labels = [
      "Default",
      "Brown",
      "Blue",
      "Red",
      "Green",
      "Orange",
      "Teal",
      "Indigo",
      "Purple",
      "Cyan",
    ];
    return labels[index];
  }
}

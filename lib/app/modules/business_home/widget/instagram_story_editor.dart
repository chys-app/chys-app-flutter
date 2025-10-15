import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';

import '../../../core/const/app_colors.dart';

class InstagramStoryEditor extends StatefulWidget {
  final File imageFile;
  final Function(File) onSave;
  final VoidCallback onCancel;

  const InstagramStoryEditor({
    Key? key,
    required this.imageFile,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<InstagramStoryEditor> createState() => _InstagramStoryEditorState();
}

class _InstagramStoryEditorState extends State<InstagramStoryEditor> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();
  
  // Text editing state
  bool _isTextMode = false;
  bool _isTextEditing = false;
  String _currentText = '';
  Color _textColor = AppColors.textPrimary;
  double _textSize = 24.0;
  Offset _textPosition = const Offset(0.5, 0.5);
  FontWeight _fontWeight = FontWeight.normal;
  final TextAlign _textAlign = TextAlign.center;
  
  // UI state
  final bool _showColorPicker = false;
  final bool _showFontOptions = false;
  bool _showTextOptions = false;
  bool _showFitOptions = false;
  bool _showStickerOptions = false;
  bool _isDrawingMode = false;
  
  // Drawing state
  List<List<Offset>> _drawingStrokes = []; // Store all completed strokes
  List<Offset> _currentStroke = []; // Current stroke being drawn
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 3.0;
  
  // Undo functionality
  final List<List<List<Offset>>> _drawingHistory = []; // For undo functionality - stores complete state
  final List<_DraggableSticker> _stickerHistory = []; // For sticker undo
  
  // Sticker state
  final List<_DraggableSticker> _stickers = [];
  String? _selectedSticker;
  
  // Predefined stickers
  final List<String> _stickerOptions = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
    '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
    '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
    '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
    '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️',
    '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈', '♉',
  ];
  
  // Image fit options
  BoxFit _imageFit = BoxFit.contain;
  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;
  
  // Font options
  final List<String> _fonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Inter',
  ];
  final String _selectedFont = 'Roboto';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _toggleTextMode() {
    setState(() {
      _isTextMode = !_isTextMode;
      if (_isTextMode) {
        _showTextOptions = true;
      } else {
        _showTextOptions = false;
        _isTextEditing = false;
      }
    });
  }

  void _addText() {
    setState(() {
      _isTextEditing = true;
      _currentText = _textController.text;
      _showTextOptions = true;
    });
  }

  void _updateTextPosition(Offset position) {
    setState(() {
      _textPosition = Offset(
        position.dx / MediaQuery.of(context).size.width,
        position.dy / MediaQuery.of(context).size.height,
      );
    });
  }

  void _toggleStickerMode() {
    setState(() {
      _showStickerOptions = !_showStickerOptions;
      _isDrawingMode = false;
      _showTextOptions = false;
      _showFitOptions = false;
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _showStickerOptions = false;
      _showTextOptions = false;
      _showFitOptions = false;
    });
  }

  void _addSticker(String sticker) {
    setState(() {
      final stickerId = '${sticker}_${DateTime.now().millisecondsSinceEpoch}';
      _stickers.add(
        _DraggableSticker(
          id: stickerId,
          sticker: sticker,
          position: Offset(
            MediaQuery.of(context).size.width * 0.3,
            MediaQuery.of(context).size.height * 0.3,
          ),
          onPositionChanged: (newPosition) {
            setState(() {
              // Find and update the sticker position by ID
              for (int i = 0; i < _stickers.length; i++) {
                if (_stickers[i].id == stickerId) {
                  _stickers[i] = _DraggableSticker(
                    id: stickerId,
                    sticker: sticker,
                    position: newPosition,
                    onPositionChanged: _stickers[i].onPositionChanged,
                  );
                  break;
                }
              }
            });
          },
        ),
      );
      _showStickerOptions = false;
    });
  }

  void _startDrawing(Offset position) {
    if (_isDrawingMode) {
      setState(() {
        _currentStroke = [position];
      });
    }
  }

  void _updateDrawing(Offset position) {
    if (_isDrawingMode && _currentStroke.isNotEmpty) {
      setState(() {
        _currentStroke.add(position);
      });
    }
  }

  void _endDrawing() {
    if (_isDrawingMode && _currentStroke.isNotEmpty) {
      setState(() {
        // Save current state to history for undo
        _drawingHistory.add(List.from(_drawingStrokes));
        // Add completed stroke to drawing strokes
        _drawingStrokes.add(List.from(_currentStroke));
        // Clear current stroke
        _currentStroke = [];
      });
    }
  }

  void _undoDrawing() {
    if (_drawingHistory.isNotEmpty) {
      setState(() {
        _drawingStrokes = _drawingHistory.removeLast();
      });
    }
  }

  void _undoSticker() {
    if (_stickers.isNotEmpty) {
      setState(() {
        _stickerHistory.add(_stickers.removeLast());
      });
    }
  }

  void _redoSticker() {
    if (_stickerHistory.isNotEmpty) {
      setState(() {
        _stickers.add(_stickerHistory.removeLast());
      });
    }
  }

  void _saveStory() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(image);
        widget.onSave(file);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save story');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main image with text overlay
          Screenshot(
            controller: _screenshotController,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Background image with full screen display
                  GestureDetector(
                    onScaleUpdate: (details) {
                      setState(() {
                        _imageScale = (_imageScale * details.scale).clamp(0.5, 3.0);
                        _imageOffset += details.focalPointDelta;
                      });
                    },
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translate(_imageOffset.dx, _imageOffset.dy)
                        ..scale(_imageScale),
                      child: Image.file(
                        widget.imageFile,
                        fit: _imageFit,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  
                  // Text overlay
                  if (_currentText.isNotEmpty)
                    Positioned(
                      left: _textPosition.dx * MediaQuery.of(context).size.width - 100,
                      top: _textPosition.dy * MediaQuery.of(context).size.height - 20,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          _updateTextPosition(details.globalPosition);
                        },
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            _currentText,
                            style: GoogleFonts.getFont(
                              _selectedFont,
                              color: _textColor,
                              fontSize: _textSize,
                              fontWeight: _fontWeight,
                            ),
                            textAlign: _textAlign,
                          ),
                        ),
                      ),
                    ),
                  
                  // Stickers overlay
                  ..._stickers.map((sticker) => sticker.build(context)),
                  
                  // Drawing canvas
                  if (_isDrawingMode)
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: (details) => _startDrawing(details.globalPosition),
                        onPanUpdate: (details) => _updateDrawing(details.globalPosition),
                        onPanEnd: (details) => _endDrawing(),
                        child: CustomPaint(
                          painter: DrawingPainter(
                            completedStrokes: _drawingStrokes,
                            currentStroke: _currentStroke,
                            color: _drawingColor,
                            strokeWidth: _drawingStrokeWidth,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const Text(
                        'New Story',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _saveStory,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom toolbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Text button
                      _buildToolButton(
                        icon: Icons.text_fields,
                        label: 'Text',
                        isActive: _isTextMode,
                        onTap: _toggleTextMode,
                      ),
                      
                      // Fit button
                      _buildToolButton(
                        icon: Icons.fit_screen,
                        label: 'Fit',
                        isActive: _showFitOptions,
                        onTap: () {
                          setState(() {
                            _showFitOptions = !_showFitOptions;
                          });
                        },
                      ),
                      
                      // Sticker button
                      _buildToolButton(
                        icon: Icons.emoji_emotions,
                        label: 'Sticker',
                        isActive: _showStickerOptions,
                        onTap: _toggleStickerMode,
                      ),
                      
                      // Draw button
                      _buildToolButton(
                        icon: Icons.brush,
                        label: 'Draw',
                        isActive: _isDrawingMode,
                        onTap: _toggleDrawingMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Text input overlay
          if (_isTextMode && !_isTextEditing)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Text input field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type something...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Add text button
                    GestureDetector(
                      onTap: _addText,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Add Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Text editing options
          if (_showTextOptions && _currentText.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Color picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildColorOption(Colors.white),
                        _buildColorOption(Colors.black),
                        _buildColorOption(Colors.red),
                        _buildColorOption(Colors.blue),
                        _buildColorOption(Colors.green),
                        _buildColorOption(Colors.yellow),
                        _buildColorOption(Colors.purple),
                        _buildColorOption(Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Font size slider
                    Row(
                      children: [
                        const Text(
                          'Size',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                        Expanded(
                          child: Slider(
                            value: _textSize,
                            min: 16,
                            max: 48,
                            activeColor: AppColors.blue,
                            inactiveColor: AppColors.border,
                            onChanged: (value) {
                              setState(() {
                                _textSize = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    // Font weight options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFontWeightOption('Normal', FontWeight.normal),
                        _buildFontWeightOption('Bold', FontWeight.bold),
                        _buildFontWeightOption('Light', FontWeight.w300),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Image fit options
          if (_showFitOptions)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Image Fit',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fit options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFitOption('Full', BoxFit.contain),
                        _buildFitOption('Cover', BoxFit.cover),
                        _buildFitOption('Fill', BoxFit.fill),
                        _buildFitOption('Fit Width', BoxFit.fitWidth),
                        _buildFitOption('Fit Height', BoxFit.fitHeight),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Reset button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageScale = 1.0;
                          _imageOffset = Offset.zero;
                          _showFitOptions = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sticker options
          if (_showStickerOptions)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Choose Sticker',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Undo/Redo buttons for stickers
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _stickers.isNotEmpty ? _undoSticker : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _stickers.isNotEmpty ? AppColors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.undo,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Undo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _stickerHistory.isNotEmpty ? _redoSticker : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _stickerHistory.isNotEmpty ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.redo,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Redo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _stickerHistory.addAll(_stickers);
                              _stickers.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _stickers.isNotEmpty ? Colors.red : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sticker grid
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _stickerOptions.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _addSticker(_stickerOptions[index]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Text(
                                  _stickerOptions[index],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Drawing options
          if (_isDrawingMode)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Drawing Tools',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Drawing color options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDrawingColorOption(Colors.white),
                        _buildDrawingColorOption(Colors.black),
                        _buildDrawingColorOption(Colors.red),
                        _buildDrawingColorOption(Colors.blue),
                        _buildDrawingColorOption(Colors.green),
                        _buildDrawingColorOption(Colors.yellow),
                        _buildDrawingColorOption(Colors.purple),
                        _buildDrawingColorOption(Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stroke width slider
                    Row(
                      children: [
                        const Text(
                          'Size',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                        Expanded(
                          child: Slider(
                            value: _drawingStrokeWidth,
                            min: 1,
                            max: 10,
                            activeColor: AppColors.blue,
                            inactiveColor: AppColors.border,
                            onChanged: (value) {
                              setState(() {
                                _drawingStrokeWidth = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Undo button for drawing
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _drawingHistory.isNotEmpty ? _undoDrawing : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _drawingHistory.isNotEmpty ? AppColors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.undo,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Undo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _drawingStrokes.clear();
                              _drawingHistory.clear();
                              _currentStroke.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _drawingStrokes.isNotEmpty ? Colors.red : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.blue : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _textColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _textColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFontWeightOption(String label, FontWeight weight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fontWeight = weight;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _fontWeight == weight ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _fontWeight == weight ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }

  Widget _buildFitOption(String label, BoxFit fit) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _imageFit = fit;
          _showFitOptions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _imageFit == fit ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _imageFit == fit ? Colors.white : AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _drawingColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _drawingColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> completedStrokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.completedStrokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw all completed strokes
    for (final stroke in completedStrokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
    }

    // Draw current stroke being drawn
    if (currentStroke.length > 1) {
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DraggableSticker {
  final String id;
  final String sticker;
  final Offset position;
  final Function(Offset) onPositionChanged;

  _DraggableSticker({
    required this.id,
    required this.sticker,
    required this.position,
    required this.onPositionChanged,
  });

  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 20, // Center the sticker on the touch point
      top: position.dy - 20,
      child: GestureDetector(
        onPanUpdate: (details) {
          onPositionChanged(details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            sticker,
            style: const TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}

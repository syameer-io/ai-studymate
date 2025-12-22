/// Create Note Screen
///
/// Form to create a new note.
/// Supports text entry and image/PDF with OCR text extraction.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme_config.dart';
import '../../providers/notes_provider.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../recorder/voice_recorder_screen.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _subjectFocusNode = FocusNode();

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedFile;
  String? _selectedFileType; // 'image' or 'pdf'
  bool _isExtracting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _subjectFocusNode.dispose();
    super.dispose();
  }

  // ========== FILE SELECTION ==========

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        await _processImageFile(File(photo.path));
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImageFile(File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        await _processPdfFile(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Failed to pick PDF: $e');
    }
  }

  Future<void> _processImageFile(File imageFile) async {
    setState(() {
      _isExtracting = true;
      _selectedFile = imageFile;
      _selectedFileType = 'image';
    });

    final notesProvider = context.read<NotesProvider>();
    final extractedText = await notesProvider.extractTextFromImage(imageFile);

    setState(() {
      _isExtracting = false;
    });

    if (extractedText != null) {
      _contentController.text = extractedText;
      // Auto-generate title from first line if empty
      if (_titleController.text.isEmpty) {
        final firstLine = extractedText.split('\n').first;
        _titleController.text = firstLine.length > 50
            ? '${firstLine.substring(0, 50)}...'
            : firstLine;
      }
    } else {
      _showError(notesProvider.errorMessage ?? 'Failed to extract text');
    }
  }

  Future<void> _processPdfFile(File pdfFile) async {
    setState(() {
      _isExtracting = true;
      _selectedFile = pdfFile;
      _selectedFileType = 'pdf';
    });

    final notesProvider = context.read<NotesProvider>();
    final extractedText = await notesProvider.extractTextFromPdf(pdfFile);

    setState(() {
      _isExtracting = false;
    });

    if (extractedText != null) {
      _contentController.text = extractedText;
      // Auto-generate title from filename if empty
      if (_titleController.text.isEmpty) {
        final fileName = pdfFile.path.split('/').last.split('\\').last;
        _titleController.text = fileName.replaceAll('.pdf', '');
      }
    } else {
      _showError(notesProvider.errorMessage ?? 'Failed to extract text from PDF');
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileType = null;
    });
  }

  void _openVoiceRecorder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceRecorderScreen()),
    );
  }

  // ========== SAVE NOTE ==========

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final notesProvider = context.read<NotesProvider>();
    bool success;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final subject = _subjectController.text.trim().isEmpty
        ? null
        : _subjectController.text.trim();

    if (_selectedFile != null && _selectedFileType == 'image') {
      success = await notesProvider.createNoteFromImage(
        title: title,
        imageFile: _selectedFile!,
        subject: subject,
      );
    } else if (_selectedFile != null && _selectedFileType == 'pdf') {
      success = await notesProvider.createNoteFromPdf(
        title: title,
        pdfFile: _selectedFile!,
        subject: subject,
      );
    } else {
      success = await notesProvider.createTextNote(
        title: title,
        content: content,
        subject: subject,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SuccessMessages.noteSaved),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showError(notesProvider.errorMessage ?? ErrorMessages.noteSaveFailed);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
        actions: [
          Consumer<NotesProvider>(
            builder: (context, notesProvider, _) {
              return TextButton(
                onPressed: notesProvider.isSaving ? null : _saveNote,
                child: notesProvider.isSaving
                    ? const SmallLoadingIndicator(size: 20)
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source buttons
                  _buildSourceButtons(),
                  const SizedBox(height: 16),

                  // Selected file preview
                  if (_selectedFile != null) _buildFilePreview(),

                  // Title field
                  CustomTextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    labelText: 'Title',
                    hintText: 'Enter note title',
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    validator: Validators.validateNoteTitle,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_contentFocusNode);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Content field
                  ContentTextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    labelText: 'Content',
                    hintText: 'Enter note content or extract from image/PDF',
                    validator: Validators.validateNoteContent,
                    minLines: 8,
                    maxLines: 20,
                  ),
                  const SizedBox(height: 16),

                  // Subject field (optional)
                  CustomTextField(
                    controller: _subjectController,
                    focusNode: _subjectFocusNode,
                    labelText: 'Subject (optional)',
                    hintText: 'e.g., Math, Physics, History',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  Consumer<NotesProvider>(
                    builder: (context, notesProvider, _) {
                      return LoadingButton(
                        isLoading: notesProvider.isSaving,
                        onPressed: _saveNote,
                        label: 'Save Note',
                        icon: Icons.save,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Extraction loading overlay
          if (_isExtracting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Extracting text...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add from source',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    color: AppColors.primary,
                    onTap: _captureImage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.image_outlined,
                    label: 'Gallery',
                    color: AppColors.info,
                    onTap: _pickImageFromGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    color: AppColors.error,
                    onTap: _pickPdfFile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.mic_outlined,
                    label: 'Voice',
                    color: AppColors.accent,
                    onTap: _openVoiceRecorder,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // File type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedFileType == 'image'
                    ? AppColors.info.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _selectedFileType == 'image'
                    ? Icons.image_outlined
                    : Icons.picture_as_pdf_outlined,
                color: _selectedFileType == 'image'
                    ? AppColors.info
                    : AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFileType == 'image' ? 'Image selected' : 'PDF selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Text extracted and added to content',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: _clearSelectedFile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Source button widget
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

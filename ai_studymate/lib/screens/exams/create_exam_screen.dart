/// Create/Edit Exam Screen
///
/// Form to create or edit an exam with:
/// - Name, subject, date, time, location
/// - Syllabus topics management
/// - Reminder days configuration

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';

class CreateExamScreen extends StatefulWidget {
  /// Exam to edit (null for create mode)
  final ExamModel? editExam;

  const CreateExamScreen({super.key, this.editExam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _syllabusController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay? _selectedTime;
  List<String> _syllabus = [];
  List<int> _reminderDays = [7, 3, 1];

  bool get _isEditing => widget.editExam != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFormFromExam(widget.editExam!);
    }
  }

  void _populateFormFromExam(ExamModel exam) {
    _nameController.text = exam.name;
    _subjectController.text = exam.subject;
    _locationController.text = exam.location ?? '';
    _selectedDate = exam.examDate;
    if (exam.examTime != null && exam.examTime!.isNotEmpty) {
      _selectedTime = _parseTimeString(exam.examTime!);
    }
    _syllabus = List.from(exam.syllabus);
    _reminderDays = List.from(exam.reminderDays);
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _locationController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addSyllabusTopic() {
    final topic = _syllabusController.text.trim();
    if (topic.isNotEmpty && !_syllabus.contains(topic)) {
      setState(() {
        _syllabus.add(topic);
        _syllabusController.clear();
      });
    }
  }

  void _removeSyllabusTopic(int index) {
    setState(() => _syllabus.removeAt(index));
  }

  void _toggleReminderDay(int day) {
    setState(() {
      if (_reminderDays.contains(day)) {
        _reminderDays.remove(day);
      } else {
        _reminderDays.add(day);
        _reminderDays.sort((a, b) => b.compareTo(a));
      }
    });
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    final examProvider = context.read<ExamProvider>();
    bool success;

    if (_isEditing) {
      final updatedExam = widget.editExam!.copyWith(
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        examDate: _selectedDate,
        examTime: _formatTimeOfDay(_selectedTime),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        syllabus: _syllabus,
        reminderDays: _reminderDays.isEmpty ? [7, 3, 1] : _reminderDays,
      );
      success = await examProvider.updateExam(updatedExam);
    } else {
      success = await examProvider.createExam(
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        examDate: _selectedDate,
        examTime: _formatTimeOfDay(_selectedTime),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        syllabus: _syllabus,
        reminderDays: _reminderDays.isEmpty ? [7, 3, 1] : _reminderDays,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Exam updated successfully' : 'Exam created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(examProvider.errorMessage ?? 'Failed to save exam'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exam' : 'New Exam'),
        actions: [
          Consumer<ExamProvider>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isSaving ? null : _saveExam,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exam name field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Exam Name *',
                  hintText: 'e.g., Final Exam, Midterm',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an exam name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subject field
              TextFormField(
                controller: _subjectController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Mathematics, Physics',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Time picker (optional)
              _buildTimePicker(),
              const SizedBox(height: 16),

              // Location field (optional)
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g., Room 101, Building A',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Syllabus section
              _buildSyllabusSection(),
              const SizedBox(height: 24),

              // Reminder days section
              _buildReminderSection(),
              const SizedBox(height: 32),

              // Save button
              Consumer<ExamProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton.icon(
                    onPressed: provider.isSaving ? null : _saveExam,
                    icon: provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Update Exam' : 'Create Exam'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Exam Date *',
          prefixIcon: Icon(Icons.calendar_today),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Exam Time (optional)',
          prefixIcon: const Icon(Icons.access_time),
          suffixIcon: _selectedTime != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedTime = null),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _selectedTime != null
              ? _selectedTime!.format(context)
              : 'Tap to select time',
          style: TextStyle(
            fontSize: 16,
            color: _selectedTime != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSyllabusSection() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Syllabus Topics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_syllabus.isNotEmpty)
                  Text(
                    '${_syllabus.length} topics',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Add topic row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _syllabusController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Add a topic...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addSyllabusTopic(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSyllabusTopic,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            // Topics list
            if (_syllabus.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No topics added yet. Add topics you need to study for this exam.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...List.generate(_syllabus.length, (index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(_syllabus[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: () => _removeSyllabusTopic(index),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    final availableDays = [14, 7, 3, 1];

    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Reminder Days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get reminded before your exam',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableDays.map((day) {
                final isSelected = _reminderDays.contains(day);
                return FilterChip(
                  label: Text(day == 1 ? '1 day before' : '$day days before'),
                  selected: isSelected,
                  onSelected: (_) => _toggleReminderDay(day),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

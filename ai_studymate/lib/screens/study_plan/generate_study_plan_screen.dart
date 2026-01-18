/// Generate Study Plan Screen
///
/// Form screen to create a new study plan.
/// Allows users to add subjects with difficulty and exam dates,
/// set study preferences, and generate a personalized schedule.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/study_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_plan_provider.dart';
import 'study_plan_detail_screen.dart';

class GenerateStudyPlanScreen extends StatefulWidget {
  const GenerateStudyPlanScreen({super.key});

  @override
  State<GenerateStudyPlanScreen> createState() => _GenerateStudyPlanScreenState();
}

class _GenerateStudyPlanScreenState extends State<GenerateStudyPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Subject list
  final List<_SubjectFormData> _subjects = [];

  // Study preferences
  int _hoursPerDay = 4;
  String _preferredTime = 'morning';

  // Time options
  final List<Map<String, String>> _timeOptions = [
    {'value': 'morning', 'label': 'Morning (6AM - 12PM)'},
    {'value': 'afternoon', 'label': 'Afternoon (12PM - 6PM)'},
    {'value': 'evening', 'label': 'Evening (6PM - 10PM)'},
    {'value': 'night', 'label': 'Night (10PM - 2AM)'},
  ];

  @override
  void initState() {
    super.initState();
    // Start with one empty subject
    _addSubject();
  }

  void _addSubject() {
    setState(() {
      _subjects.add(_SubjectFormData());
    });
  }

  void _removeSubject(int index) {
    if (_subjects.length > 1) {
      setState(() {
        _subjects.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(int index) async {
    final subject = _subjects[index];
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: subject.examDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        subject.examDate = picked;
      });
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all subjects have dates
    for (final subject in _subjects) {
      if (subject.examDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select exam dates for all subjects'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Convert to StudySubject list
    final subjects = _subjects.map((s) => StudySubject(
      name: s.nameController.text.trim(),
      difficulty: s.difficulty,
      examDate: s.examDate!,
    )).toList();

    // Initialize provider if needed
    final authProvider = context.read<AuthProvider>();
    final studyPlanProvider = context.read<StudyPlanProvider>();

    if (!authProvider.isAuthenticated || authProvider.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to generate a study plan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    studyPlanProvider.initialize(authProvider.uid);

    // Generate plan
    final plan = await studyPlanProvider.generatePlan(
      subjects: subjects,
      availableHoursPerDay: _hoursPerDay,
      preferredStudyTime: _preferredTime,
    );

    if (!mounted) return;

    if (plan != null) {
      // Navigate to detail screen
      studyPlanProvider.selectPlan(plan);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StudyPlanDetailScreen(),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(studyPlanProvider.errorMessage ?? 'Failed to generate study plan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyPlanProvider = context.watch<StudyPlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Study Plan'),
      ),
      body: studyPlanProvider.isGenerating
          ? _buildLoadingState()
          : _buildForm(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating your personalized study plan...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subjects section
          _buildSectionHeader('Subjects', Icons.menu_book),
          const SizedBox(height: 8),
          Text(
            'Add the subjects you want to study and their exam dates',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Subject cards
          ..._subjects.asMap().entries.map((entry) {
            return _buildSubjectCard(entry.key, entry.value);
          }),

          // Add subject button
          OutlinedButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add),
            label: const Text('Add Subject'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),

          // Study preferences section
          _buildSectionHeader('Study Preferences', Icons.settings),
          const SizedBox(height: 16),

          // Hours per day slider
          _buildHoursSlider(),
          const SizedBox(height: 24),

          // Preferred study time
          _buildTimeSelector(),
          const SizedBox(height: 32),

          // Generate button
          ElevatedButton(
            onPressed: _generatePlan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.primary,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text(
                  'Generate Study Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(int index, _SubjectFormData subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with remove button
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Subject ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_subjects.length > 1)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.error, size: 20),
                    onPressed: () => _removeSubject(index),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject name
            TextFormField(
              controller: subject.nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Mathematics, Physics',
                prefixIcon: Icon(Icons.subject),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Difficulty dropdown
            DropdownButtonFormField<String>(
              value: subject.difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty Level',
                prefixIcon: Icon(Icons.speed),
              ),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Easy')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'hard', child: Text('Hard')),
              ],
              onChanged: (value) {
                setState(() {
                  subject.difficulty = value ?? 'medium';
                });
              },
            ),
            const SizedBox(height: 16),

            // Exam date picker
            InkWell(
              onTap: () => _selectDate(index),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Exam Date',
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: subject.examDate == null ? null : null,
                ),
                child: Text(
                  subject.examDate != null
                      ? DateFormat('EEEE, MMM d, yyyy').format(subject.examDate!)
                      : 'Select exam date',
                  style: TextStyle(
                    color: subject.examDate != null
                        ? AppColors.textPrimary
                        : AppColors.textLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Hours Per Day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_hoursPerDay ${_hoursPerDay == 1 ? 'hour' : 'hours'}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _hoursPerDay.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_hoursPerDay hours',
              onChanged: (value) {
                setState(() {
                  _hoursPerDay = value.round();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 hour', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                Text('12 hours', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Preferred Study Time',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_timeOptions.map((option) {
              final isSelected = _preferredTime == option['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _preferredTime = option['value']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getTimeIcon(option['value']!),
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          option['label']!,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  IconData _getTimeIcon(String time) {
    switch (time) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.nights_stay;
      case 'night':
        return Icons.bedtime;
      default:
        return Icons.schedule;
    }
  }

  @override
  void dispose() {
    for (final subject in _subjects) {
      subject.nameController.dispose();
    }
    super.dispose();
  }
}

/// Helper class for subject form data
class _SubjectFormData {
  final TextEditingController nameController = TextEditingController();
  String difficulty = 'medium';
  DateTime? examDate;
}

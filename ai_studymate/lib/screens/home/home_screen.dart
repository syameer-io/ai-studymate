/// Enhanced Home Screen Dashboard
///
/// Comprehensive study dashboard with stats, upcoming exams, recent notes, and quick actions.
/// Features a warm academic editorial design aesthetic.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/exam_provider.dart';
import '../notes/notes_list_screen.dart';
import '../notes/create_note_screen.dart';
import '../notes/note_detail_screen.dart';
import '../flashcards/flashcards_list_screen.dart';
import '../flashcards/study_screen.dart';
import '../recorder/voice_recorder_screen.dart';
import '../exams/exams_list_screen.dart';
import '../exams/create_exam_screen.dart';
import '../study_plan/study_plan_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();

    // Defer data loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;

    if (userId != null && userId.isNotEmpty) {
      final notesProvider = context.read<NotesProvider>();
      final flashcardProvider = context.read<FlashcardProvider>();
      final examProvider = context.read<ExamProvider>();

      // Initialize providers if needed
      if (notesProvider.notes.isEmpty) {
        notesProvider.initialize(userId);
      }
      if (flashcardProvider.flashcards.isEmpty) {
        flashcardProvider.initialize(userId);
      }
      if (examProvider.exams.isEmpty) {
        examProvider.initialize(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final flashcardProvider = context.watch<FlashcardProvider>();
    final examProvider = context.watch<ExamProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Warm cream background
      drawer: _buildDrawer(context, authProvider),
      appBar: AppBar(
        backgroundColor: const Color(0xFF922B3E), // Burgundy
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'AI StudyMate',
          style: GoogleFonts.crimsonText(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Profile button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    authProvider.initials,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onPressed: () => _showProfileDialog(context),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              _buildHeader(authProvider),

              // Stats Cards
              _buildStatsSection(notesProvider, flashcardProvider, examProvider),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Upcoming Exams
              _buildUpcomingExams(examProvider),

              const SizedBox(height: 24),

              // Recent Notes
              _buildRecentNotes(notesProvider),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return _StaggeredAnimation(
      delay: 0,
      controller: _animationController,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF922B3E), // Burgundy
              const Color(0xFF7A2333),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF922B3E).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authProvider.displayName,
                style: GoogleFonts.crimsonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Ready to ace your exams? 📚',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(NotesProvider notesProvider, FlashcardProvider flashcardProvider, ExamProvider examProvider) {
    final totalNotes = notesProvider.notes.length;
    final flashcardsDue = flashcardProvider.flashcards.where((fc) {
      return fc.nextReviewAt != null && fc.nextReviewAt!.isBefore(DateTime.now());
    }).length;
    final upcomingExamsCount = examProvider.upcomingExams.length;
    final nextExam = examProvider.upcomingExams.isNotEmpty ? examProvider.upcomingExams.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _StaggeredAnimation(
            delay: 100,
            controller: _animationController,
            child: Text(
              'Your Study Overview',
              style: GoogleFonts.crimsonText(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StaggeredAnimation(
                  delay: 150,
                  controller: _animationController,
                  child: _StatCard(
                    icon: Icons.library_books_rounded,
                    value: totalNotes.toString(),
                    label: 'Total Notes',
                    color: const Color(0xFF6C63FF),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF5A54D8)],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StaggeredAnimation(
                  delay: 200,
                  controller: _animationController,
                  child: _StatCard(
                    icon: Icons.layers_rounded,
                    value: flashcardsDue.toString(),
                    label: 'Cards Due',
                    color: const Color(0xFF2EC4B6),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF26A89A)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StaggeredAnimation(
            delay: 250,
            controller: _animationController,
            child: _NextExamCard(
              nextExam: nextExam,
              upcomingCount: upcomingExamsCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredAnimation(
            delay: 300,
            controller: _animationController,
            child: Text(
              'Quick Actions',
              style: GoogleFonts.crimsonText(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StaggeredAnimation(
                  delay: 350,
                  controller: _animationController,
                  child: _QuickActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Add Note',
                    color: const Color(0xFF6C63FF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateNoteScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StaggeredAnimation(
                  delay: 400,
                  controller: _animationController,
                  child: _QuickActionButton(
                    icon: Icons.mic_rounded,
                    label: 'Record',
                    color: const Color(0xFFFF6B6B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VoiceRecorderScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StaggeredAnimation(
                  delay: 450,
                  controller: _animationController,
                  child: _QuickActionButton(
                    icon: Icons.school_rounded,
                    label: 'Study Cards',
                    color: const Color(0xFF2EC4B6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StaggeredAnimation(
                  delay: 500,
                  controller: _animationController,
                  child: _QuickActionButton(
                    icon: Icons.event_rounded,
                    label: 'Add Exam',
                    color: const Color(0xFFD4AF37),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateExamScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Study Plan button (centered)
          Center(
            child: _StaggeredAnimation(
              delay: 550,
              controller: _animationController,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5 - 26,
                child: _QuickActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Study Plan',
                  color: const Color(0xFF6C63FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudyPlanListScreen()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExams(ExamProvider examProvider) {
    final upcomingExams = examProvider.upcomingExams.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredAnimation(
            delay: 600,
            controller: _animationController,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Exams',
                  style: GoogleFonts.crimsonText(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExamsListScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF922B3E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (upcomingExams.isEmpty)
            _StaggeredAnimation(
              delay: 650,
              controller: _animationController,
              child: _EmptyState(
                icon: Icons.event_available_rounded,
                message: 'No upcoming exams',
                subtitle: 'Add an exam to get started',
              ),
            )
          else
            ...upcomingExams.asMap().entries.map((entry) {
              final index = entry.key;
              final exam = entry.value;
              return _StaggeredAnimation(
                delay: 650 + (index * 50),
                controller: _animationController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExamCard(exam: exam),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentNotes(NotesProvider notesProvider) {
    final recentNotes = notesProvider.notes.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredAnimation(
            delay: 800,
            controller: _animationController,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notes',
                  style: GoogleFonts.crimsonText(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotesListScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF922B3E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (recentNotes.isEmpty)
            _StaggeredAnimation(
              delay: 850,
              controller: _animationController,
              child: _EmptyState(
                icon: Icons.note_add_rounded,
                message: 'No notes yet',
                subtitle: 'Create your first note',
              ),
            )
          else
            ...recentNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return _StaggeredAnimation(
                delay: 850 + (index * 50),
                controller: _animationController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NoteCard(note: note),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF8F0),
      child: Column(
        children: [
          // Drawer Header - Academic Editorial Style
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF922B3E), // Burgundy
                  const Color(0xFF7A2333),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF922B3E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative top border
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFF4E5C2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // User avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        child: Text(
                          authProvider.initials,
                          style: GoogleFonts.crimsonText(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User name
                    Text(
                      authProvider.displayName,
                      style: GoogleFonts.crimsonText(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // User email
                    Text(
                      authProvider.email,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Decorative bottom border
                    Container(
                      width: double.infinity,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withValues(alpha: 0.6),
                            const Color(0xFFD4AF37).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _DrawerMenuItem(
                  icon: Icons.library_books_rounded,
                  label: 'All Notes',
                  color: const Color(0xFF6C63FF),
                  delay: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotesListScreen()),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.layers_rounded,
                  label: 'All Flashcards',
                  color: const Color(0xFF2EC4B6),
                  delay: 50,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlashcardsListScreen()),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.event_rounded,
                  label: 'All Exams',
                  color: const Color(0xFFD4AF37),
                  delay: 100,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExamsListScreen()),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'All Study Plans',
                  color: const Color(0xFF922B3E),
                  delay: 150,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudyPlanListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          // Footer with decorative element
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: const Color(0xFF922B3E).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI StudyMate',
                  style: GoogleFonts.crimsonText(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF922B3E).withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  authProvider.initials,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              title: Text(authProvider.displayName),
              subtitle: Text(authProvider.email),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

}

// ========== CUSTOM WIDGETS ==========

/// Staggered animation wrapper for entrance animations
class _StaggeredAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController controller;

  const _StaggeredAnimation({
    required this.child,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay / 1200,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              delay / 1200,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final LinearGradient gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Next exam card widget
class _NextExamCard extends StatelessWidget {
  final dynamic nextExam;
  final int upcomingCount;

  const _NextExamCard({
    required this.nextExam,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    if (nextExam == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF922B3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF922B3E),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming exams',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add an exam to track',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF636E72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            nextExam.urgencyColor,
            nextExam.urgencyColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: nextExam.urgencyColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nextExam.calculatedDaysRemaining.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'DAYS',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextExam.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  nextExam.subject,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    nextExam.formattedDate,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exam card widget
class _ExamCard extends StatelessWidget {
  final dynamic exam;

  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to exam details if needed
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: exam.urgencyColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: exam.urgencyColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: exam.urgencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    exam.calculatedDaysRemaining.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: exam.urgencyColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    'days',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: exam.urgencyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exam.subject,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF636E72),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: exam.urgencyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exam.formattedDate,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: exam.urgencyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: exam.urgencyColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: exam.urgencyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Note card widget
class _NoteCard extends StatelessWidget {
  final dynamic note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final notesProvider = context.read<NotesProvider>();
        notesProvider.selectNote(note);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A54D8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getFileIcon(note.fileType),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (note.subject != null && note.subject!.isNotEmpty)
                    Text(
                      note.subject!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF636E72),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(note.createdAt),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF95A5A6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'audio':
        return Icons.mic_rounded;
      default:
        return Icons.note_alt_rounded;
    }
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF922B3E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: const Color(0xFF922B3E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF636E72),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer menu item with elegant hover and tap states
class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(
      begin: -30,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.color.withValues(alpha: 0.1),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.0),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Label
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3436),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: widget.color.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

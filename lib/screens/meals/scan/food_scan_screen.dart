import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/food_analyzer_service.dart';
import '../../../services/supabase_service.dart';

/// AI Food Scanner Screen
/// Works on both mobile and web.
/// Place at: lib/screens/meals/scan/food_scan_screen.dart
class FoodScanScreen extends StatefulWidget {
  final String userGoal;   // e.g. 'Build Muscle', 'Lose Weight'
  final String userTier;   // 'guest', 'free', 'premium'

  const FoodScanScreen({
    super.key,
    required this.userGoal,
    required this.userTier,
  });

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // Image state
  File? _imageFile;
  List<int>? _imageBytes;
  String? _imageName;

  // Result state
  bool _analyzing = false;
  bool _analyzed = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Image Picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked == null) return;

      _reset(keepImage: false);

      setState(() => _imageName = picked.name);

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      } else {
        setState(() => _imageFile = File(picked.path));
      }

      // Auto-analyze after picking
      await _analyzeImage();
    } catch (e) {
      _setError('Could not pick image: ${e.toString()}');
    }
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  Future<void> _analyzeImage() async {
    if (_imageFile == null && _imageBytes == null) return;

    setState(() {
      _analyzing = true;
      _errorMessage = null;
      _analyzed = false;
      _result = null;
    });

    try {
      final response = await FoodAnalyzerService.analyzeFood(
        imageFile: _imageFile,
        imageBytes: _imageBytes,
        fileName: _imageName ?? 'food.jpg',
        goal: widget.userGoal,
      );

      if (!mounted) return;

      if (response == null) {
        _setError('No response from server. Is Python server running?');
        return;
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        _setError('Invalid response from server.');
        return;
      }

      if (data['is_food'] == false) {
        _setError(data['message'] as String? ??
            'No food detected. Please take a clear photo of your meal.');
        return;
      }

      setState(() {
        _analyzing = false;
        _analyzed = true;
        _result = data;
      });
      _animController.forward(from: 0);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _errorMessage = msg;
    });
  }

  void _reset({bool keepImage = false}) {
    setState(() {
      if (!keepImage) {
        _imageFile = null;
        _imageBytes = null;
        _imageName = null;
      }
      _analyzed = false;
      _result = null;
      _errorMessage = null;
    });
    _animController.reset();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 700;

    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF111111) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222222) : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: textPrimary),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('AI Food Scanner',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary)),
          ],
        ),
        actions: [
          if (_analyzed || _imageFile != null || _imageBytes != null)
            GestureDetector(
              onTap: () => _reset(),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  color: cardColor,
                ),
                child: Text('New Scan',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 60 : 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal badge
                _buildGoalBadge(textSecondary),
                const SizedBox(height: 16),

                // Image area
                _buildImageArea(isDark, textPrimary, textSecondary,
                    cardColor, borderColor),
                const SizedBox(height: 16),

                // Error
                if (_errorMessage != null) _buildError(),

                // Analyzing loader
                if (_analyzing) _buildAnalyzing(textPrimary, textSecondary, cardColor),

                // Results
                if (_analyzed && _result != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildResults(isDark, textPrimary,
                        textSecondary, cardColor, borderColor),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Goal Badge ────────────────────────────────────────────────────────────

  Widget _buildGoalBadge(Color textSecondary) {
    final goalColors = {
      'Build Muscle': const Color(0xFF2979FF),
      'Lose Weight': const Color(0xFFFF6D00),
      'Improve Fitness': AppColors.primary,
      'Maintain Weight': const Color(0xFFAA00FF),
    };
    final goalIcons = {
      'Build Muscle': '💪',
      'Lose Weight': '🔥',
      'Improve Fitness': '⚡',
      'Maintain Weight': '⚖️',
    };
    final color = goalColors[widget.userGoal] ?? AppColors.primary;
    final icon = goalIcons[widget.userGoal] ?? '🎯';

    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text('$icon  Analyzing for: ${widget.userGoal}',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  // ── Image Area ────────────────────────────────────────────────────────────

  Widget _buildImageArea(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final hasImage = _imageFile != null || _imageBytes != null;

    return Container(
      height: hasImage ? 300 : 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasImage
              ? AppColors.primary.withOpacity(0.5)
              : borderColor,
          width: hasImage ? 2 : 1,
        ),
        color: cardColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: hasImage
            ? _buildImagePreview()
            : _buildImagePlaceholder(
                isDark, textPrimary, textSecondary),
      ),
    );
  }

  Widget _buildImagePreview() {
    Widget img;
    if (kIsWeb && _imageBytes != null) {
      img = Image.memory(
        _imageBytes! as dynamic,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (_imageFile != null) {
      img = Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity);
    } else {
      img = const SizedBox.shrink();
    }

    return Stack(fit: StackFit.expand, children: [
      img,
      // Dark overlay when analyzing
      if (_analyzing)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
                const SizedBox(height: 12),
                const Text('AI is analyzing...',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      // Re-analyze button (shown after analysis)
      if (!_analyzing && _analyzed)
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _analyzeImage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.7),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.5)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text('Re-analyze',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _buildImagePlaceholder(bool isDark, Color textPrimary,
      Color textSecondary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: const Icon(Icons.camera_alt_rounded,
              size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text('Scan your food with AI',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
        const SizedBox(height: 4),
        Text('Get calories, macros & personalized advice',
            style: TextStyle(fontSize: 12, color: textSecondary)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _pickBtn(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 12),
          _pickBtn(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ]),
      ],
    );
  }

  Widget _pickBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFF1744).withOpacity(0.08),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            size: 20, color: Color(0xFFFF1744)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_errorMessage!,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFFF1744))),
        ),
        GestureDetector(
          onTap: () => _reset(),
          child: const Icon(Icons.close_rounded,
              size: 18, color: Color(0xFFFF1744)),
        ),
      ]),
    );
  }

  // ── Analyzing Loader ──────────────────────────────────────────────────────

  Widget _buildAnalyzing(Color textPrimary, Color textSecondary, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
      ),
      child: Column(children: [
        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        const SizedBox(height: 14),
        Text('AI is analyzing your meal...',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary)),
        const SizedBox(height: 4),
        Text('Calculating nutrition & personalized advice for "${widget.userGoal}"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary)),
      ]),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final d = _result!;
    final nutrition = (d['nutrition'] as Map<String, dynamic>?) ?? {};
    final goalAlignment = (d['goal_alignment'] as Map<String, dynamic>?) ?? {};
    final suggestions = (d['suggestions'] as List<dynamic>?) ?? [];
    final alternatives = (d['alternative_meals'] as List<dynamic>?) ?? [];
    final positives = (d['positives'] as List<dynamic>?) ?? [];
    final concerns = (d['concerns'] as List<dynamic>?) ?? [];
    final ingredients = (d['ingredients_detected'] as List<dynamic>?) ?? [];
    final micronutrients = (d['micronutrients'] as Map<String, dynamic>?) ?? {};
    final mealTiming = (d['meal_timing'] as Map<String, dynamic>?) ?? {};
    final pakAlt = (d['pakistani_alternative'] as Map<String, dynamic>?) ?? {};

    final healthScore = (d['health_score'] as num?)?.toInt() ?? 0;
    final goalScore = (goalAlignment['score'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Food title ───────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['food_identified'] as String? ?? 'Food Detected',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        height: 1.1)),
                const SizedBox(height: 4),
                Text(d['description'] as String? ?? '',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _confidenceBadge(d['confidence'] as String? ?? 'medium'),
        ]),
        const SizedBox(height: 8),

        // Cuisine + Cooking method
        Row(children: [
          if (d['cuisine_type'] != null) ...[
            Icon(Icons.restaurant_menu_rounded, size: 13, color: textSecondary),
            const SizedBox(width: 4),
            Text(d['cuisine_type'] as String,
                style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(width: 12),
          ],
          if (d['cooking_method'] != null) ...[
            Icon(Icons.local_fire_department_rounded,
                size: 13, color: textSecondary),
            const SizedBox(width: 4),
            Text(d['cooking_method'] as String,
                style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
        ]),
        const SizedBox(height: 4),

        // Serving + timing
        if (d['serving_size'] != null)
          Row(children: [
            Icon(Icons.scale_rounded, size: 13, color: textSecondary),
            const SizedBox(width: 4),
            Text(d['serving_size'] as String,
                style: TextStyle(fontSize: 12, color: textSecondary)),
            if (mealTiming['best_time'] != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 13, color: textSecondary),
              const SizedBox(width: 4),
              Text(mealTiming['best_time'] as String,
                  style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ]),
        const SizedBox(height: 20),

        // ── Score cards ──────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _scoreCard('Health Score', healthScore,
                  _scoreColor(healthScore), Icons.favorite_rounded,
                  d['health_score_reason'] as String? ?? '', cardColor, borderColor)),
          const SizedBox(width: 12),
          Expanded(
              child: _scoreCard('Goal Match', goalScore,
                  _scoreColor(goalScore), Icons.track_changes_rounded,
                  goalAlignment['label'] as String? ?? '', cardColor, borderColor)),
        ]),
        const SizedBox(height: 14),

        // Goal feedback
        if (goalAlignment['feedback'] != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withOpacity(0.07),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userGoal,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(goalAlignment['feedback'] as String,
                        style: TextStyle(
                            fontSize: 12, color: textSecondary, height: 1.5)),
                  ],
                ),
              ),
            ]),
          ),
        const SizedBox(height: 20),

        // ── Macros ───────────────────────────────────────────────
        _sectionTitle('📊 Nutrition Breakdown', textPrimary),
        const SizedBox(height: 12),
        _buildMacroGrid(nutrition, cardColor, borderColor),
        const SizedBox(height: 20),

        // ── Ingredients ──────────────────────────────────────────
        if (ingredients.isNotEmpty) ...[
          _sectionTitle('🔍 Detected Ingredients', textPrimary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients
                .map((i) => _chip(i.toString(), cardColor, borderColor,
                    textPrimary, textSecondary))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // ── Micronutrients ───────────────────────────────────────
        if (micronutrients.isNotEmpty) ...[
          _sectionTitle('💊 Micronutrients', textPrimary),
          const SizedBox(height: 10),
          _buildMicroGrid(micronutrients, cardColor, borderColor,
              textPrimary, textSecondary),
          const SizedBox(height: 20),
        ],

        // ── Positives & Concerns ─────────────────────────────────
        if (positives.isNotEmpty || concerns.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (positives.isNotEmpty)
                Expanded(
                    child: _buildList('✅ Positives', positives,
                        const Color(0xFF00C853), cardColor,
                        borderColor, textPrimary, textSecondary)),
              if (positives.isNotEmpty && concerns.isNotEmpty)
                const SizedBox(width: 12),
              if (concerns.isNotEmpty)
                Expanded(
                    child: _buildList('⚠️ Concerns', concerns,
                        const Color(0xFFFF6D00), cardColor,
                        borderColor, textPrimary, textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // ── Timing tip ───────────────────────────────────────────
        if (mealTiming['reason'] != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF2979FF).withOpacity(0.07),
              border: Border.all(
                  color: const Color(0xFF2979FF).withOpacity(0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⏰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Best Time to Eat',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2979FF))),
                    const SizedBox(height: 3),
                    Text(mealTiming['reason'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // ── AI Suggestions ───────────────────────────────────────
        if (suggestions.isNotEmpty) ...[
          _sectionTitle('💡 Personalized Suggestions', textPrimary),
          const SizedBox(height: 12),
          ...suggestions.map((s) => _buildSuggestionCard(
              s as Map<String, dynamic>, cardColor, borderColor,
              textPrimary, textSecondary)),
          const SizedBox(height: 8),
        ],

        // ── Pakistani Alternative ────────────────────────────────
        if (pakAlt['exists'] == true && pakAlt['name'] != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF00897B).withOpacity(0.07),
              border: Border.all(
                  color: const Color(0xFF00897B).withOpacity(0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🇵🇰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pakAlt['name'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00897B))),
                    if (pakAlt['benefit'] != null)
                      Text(pakAlt['benefit'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // ── Alternatives ─────────────────────────────────────────
        if (alternatives.isNotEmpty) ...[
          _sectionTitle(
              '🍽  Better Alternatives for ${widget.userGoal}', textPrimary),
          const SizedBox(height: 12),
          ...alternatives.map((a) => _buildAltCard(
              a as Map<String, dynamic>, cardColor, borderColor,
              textPrimary, textSecondary)),
          const SizedBox(height: 20),
        ],

        // ── Hydration tip ────────────────────────────────────────
        if (d['hydration_tip'] != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.lightBlue.withOpacity(0.07),
              border: Border.all(color: Colors.lightBlue.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Text('💧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(d['hydration_tip'] as String,
                    style:
                        TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // ── Done button ──────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Center(
              child: Text('Done',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildMacroGrid(Map<String, dynamic> n, Color cardColor,
      Color borderColor) {
    final macros = [
      {'label': 'Calories', 'value': '${(n['calories'] as num?)?.toInt() ?? 0}', 'unit': 'kcal', 'color': const Color(0xFFFF6D00)},
      {'label': 'Protein', 'value': '${(n['protein_g'] as num?)?.toStringAsFixed(1) ?? "0"}', 'unit': 'g', 'color': const Color(0xFF2979FF)},
      {'label': 'Carbs', 'value': '${(n['carbohydrates_g'] as num?)?.toStringAsFixed(1) ?? "0"}', 'unit': 'g', 'color': const Color(0xFFAA00FF)},
      {'label': 'Fat', 'value': '${(n['fat_g'] as num?)?.toStringAsFixed(1) ?? "0"}', 'unit': 'g', 'color': const Color(0xFFFFD600)},
      {'label': 'Fiber', 'value': '${(n['fiber_g'] as num?)?.toStringAsFixed(1) ?? "0"}', 'unit': 'g', 'color': const Color(0xFF00C853)},
      {'label': 'Sugar', 'value': '${(n['sugar_g'] as num?)?.toStringAsFixed(1) ?? "0"}', 'unit': 'g', 'color': const Color(0xFFFF1744)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: macros.length,
      itemBuilder: (_, i) {
        final m = macros[i];
        final color = m['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withOpacity(0.07),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m['value'] as String,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text('${m['unit']}  ${m['label']}',
                  style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMicroGrid(Map<String, dynamic> micro, Color cardColor,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final levelColors = {
      'high': const Color(0xFF00C853),
      'moderate': const Color(0xFFFFD600),
      'low': const Color(0xFFFF6D00),
      'none': Colors.grey,
    };
    final icons = {
      'vitamin_c': '🍋',
      'vitamin_b12': '🔴',
      'iron': '⚙️',
      'calcium': '🦴',
      'potassium': '🍌',
      'zinc': '💊',
      'magnesium': '💎',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: micro.entries.map((e) {
        final level = e.value as String? ?? 'none';
        final color = levelColors[level] ?? Colors.grey;
        final icon = icons[e.key] ?? '•';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              e.key.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                  fontSize: 9, color: textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(0.15),
              ),
              child: Text(level.toUpperCase(),
                  style: TextStyle(
                      fontSize: 8, color: color, fontWeight: FontWeight.w800)),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildList(String title, List<dynamic> items, Color color,
      Color cardColor, Color borderColor, Color textPrimary,
      Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(i.toString(),
                          style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s, Color cardColor,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final priority = s['priority'] as String? ?? 'medium';
    final priorityColors = {
      'high': const Color(0xFFFF1744),
      'medium': const Color(0xFFFF6D00),
      'low': const Color(0xFF2979FF),
    };
    final color = priorityColors[priority] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardColor,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withOpacity(0.12),
              ),
              child: Text(priority.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(s['title'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(s['detail'] as String? ?? '',
              style:
                  TextStyle(fontSize: 12, color: textSecondary, height: 1.5)),
          if (s['impact'] != null) ...[
            const SizedBox(height: 4),
            Text('Impact: ${s['impact']}',
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildAltCard(Map<String, dynamic> a, Color cardColor,
      Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: const Center(
              child: Text('🍽', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['name'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              Text(a['reason'] as String? ?? '',
                  style:
                      TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
              if (a['key_benefit'] != null)
                Text(a['key_benefit'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary)),
            ],
          ),
        ),
        if (a['estimated_calories'] != null)
          Column(children: [
            Text('${a['estimated_calories']}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6D00))),
            const Text('kcal',
                style: TextStyle(fontSize: 9, color: Color(0xFFFF6D00))),
          ]),
      ]),
    );
  }

  Widget _chip(String label, Color cardColor, Color borderColor,
      Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: textPrimary)),
    );
  }

  Widget _confidenceBadge(String confidence) {
    final colors = {
      'high': const Color(0xFF00C853),
      'medium': const Color(0xFFFFD600),
      'low': const Color(0xFFFF6D00),
    };
    final color = colors[confidence] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(confidence.toUpperCase(),
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.w800)),
        Text('confidence',
            style: TextStyle(fontSize: 8, color: color.withOpacity(0.7))),
      ]),
    );
  }

  Widget _scoreCard(String label, int score, Color color, IconData icon,
      String subtitle, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text('$score/10',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 4, color: color.withOpacity(0.15)),
              FractionallySizedBox(
                widthFactor: score / 10,
                child: Container(height: 4, color: color),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color textPrimary) => Text(title,
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary));

  Color _scoreColor(int score) {
    if (score >= 8) return const Color(0xFF00C853);
    if (score >= 6) return const Color(0xFFFFD600);
    if (score >= 4) return const Color(0xFFFF6D00);
    return const Color(0xFFFF1744);
  }
}
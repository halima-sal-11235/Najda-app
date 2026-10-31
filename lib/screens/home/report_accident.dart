import 'package:flutter/material.dart';

// 1. Data model for questions and options
class QuestionModel {
  final String questionText;
  final List<String> options;

  QuestionModel({required this.questionText, required this.options});
}

// 2. Main Reusable Questionnaire Screen
class AccidentQuestionnaireScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final Function(Map<int, String> answers) OnCompleted;
  final VoidCallback? onCancel;

  const AccidentQuestionnaireScreen({
    super.key,
    required this.questions,
    required this.OnCompleted,
    this.onCancel,
  });

  @override
  State<AccidentQuestionnaireScreen> createState() =>
      _AccidentQuestionnaireScreenState();
}

class _AccidentQuestionnaireScreenState
    extends State<AccidentQuestionnaireScreen> {
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};

  // Theme Colors based on design
  static const Color primaryNavy = Color(0xFF10283F);
  static const Color tealAccent = Color(0xFF176B74);
  static const Color tealLightBg = Color(0xFFEAF5F5);
  static const Color greyBorder = Color(0xFFE2E8F0);

  void _nextStep() {
    if (_selectedAnswers[_currentIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد إجابة للمتابعة')),
      );
      return;
    }

    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.OnCompleted(_selectedAnswers);
    }
  }

  void _skip() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.OnCompleted(_selectedAnswers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;
    final String? selectedOption = _selectedAnswers[_currentIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Progress indicator text and Skip button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} من ${widget.questions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    GestureDetector(
                      onTap: _skip,
                      child: const Text(
                        'تخطي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tealAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Top Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(tealAccent),
                  ),
                ),

                const SizedBox(height: 40),

                // Question Title
                Text(
                  currentQuestion.questionText,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),

                const SizedBox(height: 32),

                // Options Grid (2 Columns)
                Expanded(
                  child: GridView.builder(
                    itemCount: currentQuestion.options.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isSelected = selectedOption == option;

                      return _OptionCard(
                        text: option,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentIndex] = option;
                          });
                        },
                      );
                    },
                  ),
                ),

                // Bottom Action Buttons
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == widget.questions.length - 1
                        ? 'إرسال التقرير'
                        : 'التالي',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
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

// 3. Option Grid Tile Component
class _OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? _AccidentQuestionnaireScreenState.tealLightBg
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _AccidentQuestionnaireScreenState.tealAccent
                : _AccidentQuestionnaireScreenState.greyBorder,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? _AccidentQuestionnaireScreenState.tealAccent
                    : _AccidentQuestionnaireScreenState.primaryNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

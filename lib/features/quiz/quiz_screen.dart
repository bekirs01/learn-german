import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';
import 'package:lingo_core/features/quiz/quiz_widgets.dart';

/// Quiz chrome is frozen to the Translation Language captured at launch.
String _quizCopy(
  BuildContext context,
  String key, {
  Map<String, String> params = const <String, String>{},
}) {
  final _QuizCopyScope? scope = context
      .dependOnInheritedWidgetOfExactType<_QuizCopyScope>();
  return UiStrings.resolve(
    key,
    languageCode: scope?.languageCode,
    overlay: scope?.overlay ?? const <String, String>{},
    params: params,
  );
}

final class _QuizCopyScope extends InheritedWidget {
  const _QuizCopyScope({
    required this.languageCode,
    required this.overlay,
    required super.child,
  });

  final String? languageCode;
  final Map<String, String> overlay;

  @override
  bool updateShouldNotify(_QuizCopyScope oldWidget) {
    return oldWidget.languageCode != languageCode ||
        !mapEquals(oldWidget.overlay, overlay);
  }
}

/// In-memory quiz player with light motion and immediate answer feedback.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.start,
    required this.request,
    this.onWrongAnswer,
    this.onCorrectAnswer,
  });

  final QuizStartResult start;
  final QuizLaunchRequest request;

  /// Optional hook around the Wrong Answers store. Persistence is owned by
  /// launch wiring, not this widget.
  final ValueChanged<QuizWrongAnswer>? onWrongAnswer;

  /// Optional hook for a later correct answer of a stored miss.
  final ValueChanged<QuizCorrectAnswer>? onCorrectAnswer;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _tapLock = Duration(milliseconds: 260);

  final QuizEngine _engine = QuizEngine();
  late final AnimationController _feedback;
  late final FocusNode _typingFocus;
  QuizSession? _session;
  String? _selectedOptionId;
  final List<String> _builtTokens = <String>[];
  final TextEditingController _typingController = TextEditingController();
  bool _handling = false;
  DateTime? _lastTap;
  String? _copyLanguage;
  Map<String, String> _copyOverlay = const <String, String>{};
  bool _copyFrozen = false;

  @override
  void initState() {
    super.initState();
    _session = widget.start.session;
    _feedback = AnimationController(
      vsync: this,
      duration: LingoMotion.entrance,
    );
    _typingFocus = FocusNode();
    _typingFocus.addListener(_ensureTypingVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_copyFrozen) {
      return;
    }
    _copyFrozen = true;
    final UiScope? scope = UiScope.maybeOf(context);
    _copyLanguage =
        widget.request.translationLanguageCode ??
        (scope != null && scope.languageCode.isNotEmpty
            ? scope.languageCode
            : null);
    _copyOverlay = Map<String, String>.unmodifiable(
      scope?.overlay ?? const <String, String>{},
    );
  }

  @override
  void dispose() {
    _feedback.dispose();
    _typingFocus.removeListener(_ensureTypingVisible);
    _typingFocus.dispose();
    _typingController.dispose();
    super.dispose();
  }

  QuizSession? get _readySession {
    final QuizSession? session = _session;
    if (session == null || session.questions.isEmpty) {
      return null;
    }
    return session;
  }

  bool get _isLocked {
    if (_handling) {
      return true;
    }
    final DateTime? lastTap = _lastTap;
    if (lastTap == null) {
      return false;
    }
    return DateTime.now().difference(lastTap) < _tapLock;
  }

  void _markTap() {
    _lastTap = DateTime.now();
  }

  void _ensureTypingVisible() {
    if (!_typingFocus.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = _typingFocus.context;
      if (!mounted || target == null || !_typingFocus.hasFocus) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.18,
        duration: LingoMotion.quick,
        curve: LingoMotion.standardCurve,
      );
    });
  }

  void _syncTypingFocus({
    required QuizQuestion? question,
    required bool answered,
  }) {
    if (question?.type != QuizType.typing || answered) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _typingFocus.hasFocus) {
        return;
      }
      _typingFocus.requestFocus();
    });
  }

  void _withLock(VoidCallback action) {
    if (_isLocked) {
      return;
    }
    _handling = true;
    _markTap();
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handling = false;
      }
    });
  }

  void _submit(QuizAnswerInput input) {
    final QuizSession? session = _readySession;
    if (session == null || session.hasAnsweredCurrent || session.isComplete) {
      return;
    }
    _typingFocus.unfocus();
    final QuizSession next = _engine.submit(session, input);
    if (identical(next, session)) {
      return;
    }
    final QuizAnswer? answer = next.answerForCurrent();
    if (answer != null) {
      FeedbackService.play(
        answer.isCorrect ? FeedbackEvent.quizCorrect : FeedbackEvent.quizWrong,
      );
      _playFeedback(reduceMotion: MediaQuery.disableAnimationsOf(context));
      final QuizWrongAnswer? wrong = answer.asWrongAnswer;
      if (wrong != null) {
        widget.onWrongAnswer?.call(wrong);
      }
      final QuizCorrectAnswer? correct = answer.asCorrectAnswer;
      if (correct != null) {
        widget.onCorrectAnswer?.call(correct);
      }
    }
    setState(() => _session = next);
  }

  void _selectOption(String optionId) {
    final QuizSession? session = _readySession;
    if (session == null || session.hasAnsweredCurrent || _handling) {
      return;
    }
    _handling = true;
    setState(() => _selectedOptionId = optionId);
    _submit(QuizAnswerInput.option(optionId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handling = false;
      }
    });
  }

  void _playFeedback({required bool reduceMotion}) {
    if (reduceMotion) {
      _feedback.value = 1;
      return;
    }
    _feedback.forward(from: 0);
  }

  void _continue() {
    _withLock(() {
      final QuizSession? session = _readySession;
      if (session == null || session.isComplete) {
        Navigator.of(context).maybePop();
        return;
      }
      if (!session.hasAnsweredCurrent) {
        final QuizAnswerInput? input = _inputFor(session.currentQuestion);
        if (input == null) {
          return;
        }
        _submit(input);
        return;
      }
      setState(() {
        _session = _engine.next(session);
        _selectedOptionId = null;
        _builtTokens.clear();
        _typingController.clear();
        _feedback.reset();
      });
    });
  }

  void _retry() {
    _withLock(() {
      final QuizStartResult start = QuizEngine().start(
        items: widget.request.items,
        optionPool: widget.request.optionPool,
        scriptFamily: widget.request.scriptFamily,
        textDirection: widget.request.textDirection,
        translationLanguageCode: widget.request.translationLanguageCode,
        title: widget.request.title,
        allowedTypes: widget.request.allowedTypes,
      );
      setState(() {
        _session = start.session;
        _selectedOptionId = null;
        _builtTokens.clear();
        _typingController.clear();
        _feedback.reset();
      });
    });
  }

  QuizAnswerInput? _inputFor(QuizQuestion? question) {
    if (question == null) {
      return null;
    }
    switch (question.type) {
      case QuizType.multipleChoice:
      case QuizType.reverseMultipleChoice:
        final String? optionId = _selectedOptionId;
        if (optionId == null) {
          return null;
        }
        return QuizAnswerInput.option(optionId);
      case QuizType.buildSequence:
        if (_builtTokens.length != question.expectedTokens.length) {
          return null;
        }
        return QuizAnswerInput.tokens(List<String>.from(_builtTokens));
      case QuizType.typing:
        if (_typingController.text.trim().isEmpty) {
          return null;
        }
        return QuizAnswerInput.text(_typingController.text);
    }
  }

  EdgeInsets _footerPadding(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double safe = MediaQuery.paddingOf(context).bottom;
    final double bottom = keyboard > 0
        ? LingoSpacing.md
        : LingoSpacing.lg + safe;
    return EdgeInsets.fromLTRB(
      LingoSpacing.xl,
      LingoSpacing.sm,
      LingoSpacing.xl,
      bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _QuizCopyScope(
      languageCode: _copyLanguage,
      overlay: _copyOverlay,
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final QuizSession? session = _readySession;
    if (session == null) {
      return _quizFrame(
        context,
        body: LingoContent(
          topInset: 0,
          children: <Widget>[
            LingoEmptyState(
              icon: Icons.quiz_outlined,
              title: _quizCopy(context, UiKeys.quizUnavailableTitle),
              message: _quizCopy(context, UiKeys.quizUnavailableMessage),
            ),
          ],
        ),
      );
    }

    if (session.isComplete) {
      return _QuizCompleteView(
        session: session,
        footerPadding: _footerPadding(context),
        onRetry: _retry,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final QuizQuestion? question = session.currentQuestion;
    if (question == null) {
      return _quizFrame(
        context,
        body: LingoContent(
          topInset: 0,
          children: <Widget>[
            LingoEmptyState(
              icon: Icons.quiz_outlined,
              title: _quizCopy(context, UiKeys.quizUnavailableTitle),
              message: _quizCopy(context, UiKeys.quizNoQuestion),
            ),
          ],
        ),
      );
    }

    final bool answered = session.hasAnsweredCurrent;
    final QuizAnswer? answer = session.answerForCurrent();
    final bool needsCheck =
        question.type == QuizType.buildSequence ||
        question.type == QuizType.typing;
    final String continueLabel = answered || !needsCheck
        ? _quizCopy(context, UiKeys.quizContinue)
        : _quizCopy(context, UiKeys.quizCheck);
    final bool reduceMotion = LingoMetrics.of(context).reduceMotion;
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double stackGap = metrics.isCompact
        ? LingoSpacing.sm
        : LingoSpacing.md;
    _syncTypingFocus(question: question, answered: answered);

    return _quizFrame(
      context,
      current: session.questionNumber,
      total: session.questions.length,
      footer: Padding(
        padding: _footerPadding(context),
        child: LingoPrimaryButton(
          label: continueLabel,
          status: answered && answer?.isCorrect == true
              ? LingoStatus.success
              : LingoStatus.idle,
          onPressed: answered || _inputFor(question) != null ? _continue : null,
        ),
      ),
      body: LingoContent(
        topInset: 0,
        bottomPadding: LingoSpacing.md,
        children: <Widget>[
          _QuizFeedbackMotion(
            controller: _feedback,
            isCorrect: answer?.isCorrect ?? true,
            reduceMotion: reduceMotion,
            child: _QuizPrompt(question: question),
          ),
          SizedBox(height: stackGap),
          _QuizAnswerArea(
            question: question,
            answered: answered,
            selectedOptionId: _selectedOptionId,
            builtTokens: _builtTokens,
            typingController: _typingController,
            typingFocus: _typingFocus,
            isCorrect: answer?.isCorrect,
            animation: _feedback,
            reduceMotion: reduceMotion,
            onSelectOption: _selectOption,
            onToggleToken: (String token, {required bool fromBank}) {
              if (answered) {
                return;
              }
              setState(() {
                if (fromBank) {
                  _builtTokens.add(token);
                } else {
                  final int index = _builtTokens.lastIndexOf(token);
                  if (index >= 0) {
                    _builtTokens.removeAt(index);
                  }
                }
              });
            },
            onUndo: () {
              if (answered || _builtTokens.isEmpty) {
                return;
              }
              FeedbackService.play(FeedbackEvent.selection);
              setState(() {
                _builtTokens.removeLast();
              });
            },
            onTypingChanged: (_) => setState(() {}),
            onTypingSubmitted: (_) {
              if (!answered) {
                _continue();
              }
            },
          ),
          if (answered && answer != null) ...<Widget>[
            SizedBox(height: stackGap),
            QuizOutcomePanel(
              isCorrect: answer.isCorrect,
              title: _quizCopy(
                context,
                answer.isCorrect ? UiKeys.quizCorrect : UiKeys.quizIncorrect,
              ),
              detail: answer.isCorrect
                  ? null
                  : _quizCopy(
                      context,
                      UiKeys.quizCorrectAnswer,
                      params: <String, String>{
                        'answer': question.expectedAnswer,
                      },
                    ),
              detailDirection: question.answerDirection,
              animation: _feedback,
              reduceMotion: reduceMotion,
            ),
          ],
        ],
      ),
    );
  }

  Widget _quizFrame(
    BuildContext context, {
    required Widget body,
    Widget? footer,
    int? current,
    int? total,
  }) {
    return LingoPage(
      showAppBar: false,
      footer: footer,
      body: Column(
        children: <Widget>[
          QuizTopBar(current: current, total: total),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _QuizFeedbackMotion extends StatelessWidget {
  const _QuizFeedbackMotion({
    required this.controller,
    required this.isCorrect,
    required this.reduceMotion,
    required this.child,
  });

  final AnimationController controller;
  final bool isCorrect;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return child;
    }
    final Animation<double> curved = CurvedAnimation(
      parent: controller,
      curve: LingoMotion.standardCurve,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (BuildContext context, Widget? child) {
        final double t = curved.value;
        if (isCorrect) {
          final double scale = 1 + (t < 0.5 ? t : 1 - t) * 0.06;
          return Transform.scale(scale: scale, child: child);
        }
        final double wave = t < 0.5 ? t * 2 : (1 - t) * 2;
        final double dx = (wave < 0.5 ? wave : 1 - wave) * 5;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}

class _QuizPrompt extends StatelessWidget {
  const _QuizPrompt({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool compactGlyph =
        question.kind == QuizContentKind.alphabet &&
        question.prompt.characters.length <= 3;
    final bool longPrompt = question.prompt.length > 42;
    final TextStyle? style = compactGlyph
        ? textTheme.displayLarge
        : longPrompt
        ? textTheme.headlineSmall
        : textTheme.headlineMedium;

    return Directionality(
      textDirection: quizTextDirection(question.promptDirection),
      child: Text(
        question.prompt,
        style: style,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }
}

class _QuizAnswerArea extends StatelessWidget {
  const _QuizAnswerArea({
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.selectedOptionId,
    required this.builtTokens,
    required this.typingController,
    required this.typingFocus,
    required this.animation,
    required this.reduceMotion,
    required this.onSelectOption,
    required this.onToggleToken,
    required this.onUndo,
    required this.onTypingChanged,
    required this.onTypingSubmitted,
  });

  final QuizQuestion question;
  final bool answered;
  final bool? isCorrect;
  final String? selectedOptionId;
  final List<String> builtTokens;
  final TextEditingController typingController;
  final FocusNode typingFocus;
  final Animation<double> animation;
  final bool reduceMotion;
  final ValueChanged<String> onSelectOption;
  final void Function(String token, {required bool fromBank}) onToggleToken;
  final VoidCallback onUndo;
  final ValueChanged<String> onTypingChanged;
  final ValueChanged<String> onTypingSubmitted;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuizType.multipleChoice:
      case QuizType.reverseMultipleChoice:
        return _ChoiceList(
          question: question,
          answered: answered,
          selectedOptionId: selectedOptionId,
          animation: animation,
          reduceMotion: reduceMotion,
          onSelectOption: onSelectOption,
        );
      case QuizType.buildSequence:
        return _BuildArea(
          question: question,
          answered: answered,
          isCorrect: isCorrect,
          builtTokens: builtTokens,
          onToggleToken: onToggleToken,
          onUndo: onUndo,
        );
      case QuizType.typing:
        return _TypingArea(
          question: question,
          answered: answered,
          isCorrect: isCorrect,
          controller: typingController,
          focusNode: typingFocus,
          onChanged: onTypingChanged,
          onSubmitted: onTypingSubmitted,
        );
    }
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.question,
    required this.answered,
    required this.selectedOptionId,
    required this.animation,
    required this.reduceMotion,
    required this.onSelectOption,
  });

  final QuizQuestion question;
  final bool answered;
  final String? selectedOptionId;
  final Animation<double> animation;
  final bool reduceMotion;
  final ValueChanged<String> onSelectOption;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double gap = metrics.isCompact ? LingoSpacing.sm : LingoSpacing.md;
    return Column(
      children: <Widget>[
        for (
          int index = 0;
          index < question.options.length;
          index += 1
        ) ...<Widget>[
          if (index > 0) SizedBox(height: gap),
          _ChoiceTile(
            question: question,
            option: question.options[index],
            answered: answered,
            selected: selectedOptionId == question.options[index].id,
            animation: animation,
            reduceMotion: reduceMotion,
            onPressed: () => onSelectOption(question.options[index].id),
          ),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.question,
    required this.option,
    required this.answered,
    required this.selected,
    required this.animation,
    required this.reduceMotion,
    required this.onPressed,
  });

  final QuizQuestion question;
  final QuizOption option;
  final bool answered;
  final bool selected;
  final Animation<double> animation;
  final bool reduceMotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final Color face;
    final Color outline;
    final double depth;
    if (!answered) {
      face = theme.colors.cardFill;
      outline = theme.colors.paperRim;
      depth = LingoElevation.raised;
    } else if (option.isCorrect) {
      face = theme.colors.successContainer;
      outline = theme.colors.success.withValues(alpha: 0.72);
      depth = LingoElevation.rest;
    } else if (selected) {
      face = theme.colors.dangerContainer.withValues(alpha: 0.88);
      outline = theme.colors.danger.withValues(alpha: 0.55);
      depth = LingoElevation.rest;
    } else {
      face = theme.colors.cardFill;
      outline = theme.colors.paperRim;
      depth = LingoElevation.flat;
    }
    final bool showMark = answered && (option.isCorrect || selected);
    final bool longOption = option.text.length > 36;
    final Key? stateKey = !answered
        ? null
        : option.isCorrect
        ? const Key('quiz-option-correct')
        : selected
        ? const Key('quiz-option-wrong-selected')
        : null;

    Widget tile = Directionality(
      textDirection: quizTextDirection(question.answerDirection),
      child: Opacity(
        opacity: answered && !option.isCorrect && !selected ? 0.64 : 1,
        child: LingoPressable(
          onPressed: answered ? null : onPressed,
          enableHaptics: false,
          color: face,
          depth: depth,
          borderRadius: LingoRadii.card,
          border: Border.all(
            color: outline,
            width: answered && (option.isCorrect || selected) ? 1.4 : 0.8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: LingoSpacing.xl,
            vertical: LingoSpacing.lg,
          ),
          minHeight: metrics.tapHeight(56),
          semanticLabel: option.text,
          semanticButton: !answered,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    option.text,
                    style: longOption
                        ? Theme.of(context).textTheme.bodyLarge
                        : Theme.of(context).textTheme.titleMedium,
                    softWrap: true,
                  ),
                ),
              ),
              if (showMark) ...<Widget>[
                const SizedBox(width: LingoSpacing.sm),
                QuizAnswerMark(
                  isCorrect: option.isCorrect,
                  animation: option.isCorrect
                      ? animation
                      : const AlwaysStoppedAnimation<double>(1),
                  tagged: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (answered && option.isCorrect && !reduceMotion) {
      tile = AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double t = animation.value;
          final double scale = 1 + (t < 0.55 ? t : 1 - t) * 0.035;
          return Transform.scale(scale: scale, child: child);
        },
        child: tile,
      );
    }

    return KeyedSubtree(key: stateKey, child: tile);
  }
}

class _BuildArea extends StatelessWidget {
  const _BuildArea({
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.builtTokens,
    required this.onToggleToken,
    required this.onUndo,
  });

  final QuizQuestion question;
  final bool answered;
  final bool? isCorrect;
  final List<String> builtTokens;
  final void Function(String token, {required bool fromBank}) onToggleToken;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Map<String, int> usedCounts = <String, int>{};
    for (final String token in builtTokens) {
      usedCounts[token] = (usedCounts[token] ?? 0) + 1;
    }
    final List<String> remaining = <String>[];
    final Map<String, int> remainingUsed = Map<String, int>.from(usedCounts);
    for (final String token in question.tokens) {
      final int left = remainingUsed[token] ?? 0;
      if (left > 0) {
        remainingUsed[token] = left - 1;
      } else {
        remaining.add(token);
      }
    }

    return Directionality(
      textDirection: quizTextDirection(question.answerDirection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _quizCopy(context, UiKeys.quizYourAnswer),
                  style: textTheme.labelLarge,
                ),
              ),
              if (!answered && builtTokens.isNotEmpty)
                LingoTapScale(
                  onPressed: onUndo,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: LingoSpacing.minTapTarget,
                      minHeight: LingoSpacing.minTapTarget,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        _quizCopy(context, UiKeys.quizUndo),
                        style: textTheme.labelLarge?.copyWith(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LingoSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: !answered
                    ? theme.colors.paperFill
                    : isCorrect == true
                    ? theme.colors.successContainer
                    : theme.colors.dangerContainer.withValues(alpha: 0.88),
                borderRadius: LingoRadii.card,
                border: Border.all(
                  color: !answered
                      ? theme.colors.paperRim
                      : isCorrect == true
                      ? theme.colors.success.withValues(alpha: 0.72)
                      : theme.colors.danger.withValues(alpha: 0.46),
                  width: 0.9,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(LingoSpacing.md),
                child: builtTokens.isEmpty
                    ? Text(
                        _quizCopy(context, UiKeys.quizTapTokens),
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colors.onSurfaceMuted,
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: LingoSpacing.sm,
                        runSpacing: LingoSpacing.sm,
                        children: <Widget>[
                          for (final String token in builtTokens)
                            QuizTokenChip(
                              label: token,
                              selected: true,
                              onPressed: answered
                                  ? null
                                  : () => onToggleToken(token, fromBank: false),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: LingoSpacing.lg),
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: LingoSpacing.sm,
            runSpacing: LingoSpacing.sm,
            children: <Widget>[
              for (final String token in remaining)
                QuizTokenChip(
                  label: token,
                  onPressed: answered
                      ? null
                      : () => onToggleToken(token, fromBank: true),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingArea extends StatelessWidget {
  const _TypingArea({
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final QuizQuestion question;
  final bool answered;
  final bool? isCorrect;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final Color fill = !answered
        ? theme.colors.paperFill
        : isCorrect == true
        ? theme.colors.successContainer
        : theme.colors.dangerContainer.withValues(alpha: 0.88);
    final Color outline = !answered
        ? theme.colors.paperRim
        : isCorrect == true
        ? theme.colors.success.withValues(alpha: 0.72)
        : theme.colors.danger.withValues(alpha: 0.46);
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: LingoRadii.card,
      borderSide: BorderSide(color: outline, width: 1.2),
    );
    return Directionality(
      textDirection: quizTextDirection(question.answerDirection),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !answered,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.start,
        minLines: 1,
        maxLines: 4,
        style: Theme.of(context).textTheme.headlineSmall,
        cursorColor: theme.colors.primary,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        decoration: InputDecoration(
          hintText: _quizCopy(context, UiKeys.quizTypeAnswer),
          filled: true,
          fillColor: fill,
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border,
          contentPadding: EdgeInsets.symmetric(
            horizontal: LingoSpacing.xl,
            vertical: metrics.stackTightCards
                ? LingoSpacing.md
                : LingoSpacing.lg,
          ),
        ),
      ),
    );
  }
}

class _QuizCompleteView extends StatelessWidget {
  const _QuizCompleteView({
    required this.session,
    required this.footerPadding,
    required this.onRetry,
    required this.onClose,
  });

  final QuizSession session;
  final EdgeInsets footerPadding;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final QuizResult result = session.result;
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);

    return LingoPage(
      showAppBar: false,
      footer: Padding(
        padding: footerPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LingoPrimaryButton(
              label: _quizCopy(context, UiKeys.quizTryAgain),
              onPressed: onRetry,
            ),
            const SizedBox(height: LingoSpacing.sm),
            LingoSecondaryButton(
              label: _quizCopy(context, UiKeys.quizDone),
              onPressed: onClose,
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          const QuizTopBar(),
          Expanded(
            child: LingoContent(
              topInset: 0,
              bottomPadding: LingoSpacing.lg,
              children: <Widget>[
                Text(
                  _quizCopy(context, UiKeys.quizComplete),
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colors.onSurfaceMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: LingoSpacing.sm),
                Text(
                  _quizCopy(
                    context,
                    UiKeys.quizScore,
                    params: <String, String>{
                      'correct': '${result.correctCount}',
                      'total': '${result.totalCount}',
                    },
                  ),
                  style: textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: metrics.isCompact
                      ? LingoSpacing.xl
                      : LingoSpacing.xxl,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _QuizStatCard(
                        label: _quizCopy(context, UiKeys.quizCorrect),
                        value: '${result.correctCount}',
                        color: theme.colors.successContainer,
                      ),
                    ),
                    const SizedBox(width: LingoSpacing.md),
                    Expanded(
                      child: _QuizStatCard(
                        label: _quizCopy(context, UiKeys.quizIncorrect),
                        value: '${result.incorrectCount}',
                        color: theme.colors.dangerContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizStatCard extends StatelessWidget {
  const _QuizStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoTheme theme = LingoTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(theme.colors.paperFill, color, 0.42) ?? color,
        borderRadius: LingoRadii.card,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.lg,
          vertical: LingoSpacing.xxl,
        ),
        child: Column(
          children: <Widget>[
            Text(value, style: textTheme.headlineMedium),
            const SizedBox(height: LingoSpacing.xs),
            Text(
              label,
              style: textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

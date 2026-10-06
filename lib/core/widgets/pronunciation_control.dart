import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';

/// Stops in-flight speech when a learning screen leaves the tree.
class PronunciationSession extends StatefulWidget {
  const PronunciationSession({super.key, required this.child});

  final Widget child;

  @override
  State<PronunciationSession> createState() => _PronunciationSessionState();
}

class _PronunciationSessionState extends State<PronunciationSession> {
  @override
  void dispose() {
    unawaited(PronunciationService.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Speaker control for Alphabet, Word, Phrase, and Favorites screens.
///
/// Hidden when the product disables pronunciation or the item has nothing
/// to speak (no recording and no target-language speech text).
/// Callers may pass [semanticLabel]; otherwise the learner-language catalog
/// supplies it.
class PronunciationControl extends StatefulWidget {
  const PronunciationControl({
    super.key,
    required this.clip,
    this.service,
    this.semanticLabel,
  });

  final PronunciationClip clip;
  final PronunciationService? service;
  final String? semanticLabel;

  @override
  State<PronunciationControl> createState() => _PronunciationControlState();
}

class _PronunciationControlState extends State<PronunciationControl> {
  PronunciationService get _controller {
    return widget.service ?? PronunciationService.instance;
  }

  @override
  void didUpdateWidget(covariant PronunciationControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id == widget.clip.id) {
      return;
    }
    final PronunciationService controller = _controller;
    if (controller.activeId == oldWidget.clip.id) {
      unawaited(controller.stop());
    }
  }

  @override
  void dispose() {
    final PronunciationService controller = _controller;
    if (controller.activeId == widget.clip.id) {
      unawaited(controller.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PronunciationService controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        if (!controller.isOffered(widget.clip)) {
          return const SizedBox.shrink();
        }
        final LingoTheme theme = LingoTheme.of(context);
        final bool active = controller.isPlayingClip(widget.clip);
        final bool loading =
            controller.phase == PronunciationPhase.loading &&
            controller.activeId == widget.clip.id;
        final String label =
            widget.semanticLabel ??
            UiStrings.of(context, UiKeys.audioPlayPronunciation);
        return LingoGlyphButton(
          tooltip: label,
          onPressed: () {
            unawaited(controller.playClip(widget.clip));
          },
          selected: active,
          icon: active ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          child: loading
              ? Center(
                  child: SizedBox(
                    width: LingoGlyphButton.glyphSize,
                    height: LingoGlyphButton.glyphSize,
                    child: lingoInWidgetTest
                        ? const SizedBox.shrink()
                        : CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colors.primary,
                          ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

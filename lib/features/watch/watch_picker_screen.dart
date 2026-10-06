import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';
import 'package:lingo_core/features/watch/watch_screen.dart';
import 'package:lingo_core/features/watch/watch_widgets.dart';

class WatchPickerScreen extends StatefulWidget {
  const WatchPickerScreen({super.key});

  static const ValueKey<String> screenKey = ValueKey<String>(
    'watch-picker-screen',
  );
  static const ValueKey<String> searchKey = ValueKey<String>(
    'watch-picker-search',
  );
  static const ValueKey<String> starterKey = ValueKey<String>(
    'watch-picker-starter',
  );
  static const ValueKey<String> clearKey = ValueKey<String>(
    'watch-picker-clear',
  );
  static const ValueKey<String> limitKey = ValueKey<String>(
    'watch-picker-limit',
  );

  @override
  State<WatchPickerScreen> createState() => _WatchPickerScreenState();
}

class _WatchPickerScreenState extends State<WatchPickerScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _limitMessage;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _save(WatchCompanionDraft draft) {
    return UserPreferences.instance.setWatchDraft(draft);
  }

  void _toggle(WatchCompanionDraft draft, WatchPlanItem item) {
    final WatchToggleResult result = draft.toggled(item.id, item.type);
    if (result.atLimit) {
      setState(() {
        _limitMessage = UiStrings.of(context, UiKeys.watchLimitReached);
      });
      FeedbackService.play(FeedbackEvent.error);
      return;
    }
    setState(() => _limitMessage = null);
    _save(result.draft);
    FeedbackService.play(FeedbackEvent.selection);
  }

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);

    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final ContentRepository content = ContentScope.of(context);
        final String language = ContentScope.translationLanguageOf(context);
        final WatchCompanionDraft raw = UserPreferences.instance
            .getWatchDraft();
        final WatchCompanionDraft draft = raw.pruned(
          wordIds: WatchCatalog.wordIds(content),
          phraseIds: WatchCatalog.phraseIds(content),
        );
        if (draft.wordIds.length != raw.wordIds.length ||
            draft.phraseIds.length != raw.phraseIds.length) {
          _save(draft);
        }
        final List<WatchPickerRow> rows = WatchCatalog.pickerRows(
          content: content,
          learnerLanguageCode: language,
          filter: draft.filter,
          query: _query,
        );

        return LingoPage(
          key: WatchPickerScreen.screenKey,
          title: UiStrings.of(context, UiKeys.watchChooseContent),
          body: LingoContent(
            storageKey: 'watch-picker',
            itemGap: LingoSpacing.xs,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                WatchFilterControl(
                  filter: draft.filter,
                  onChanged: (WatchContentFilter next) {
                    if (next == draft.filter) {
                      return;
                    }
                    setState(() => _limitMessage = null);
                    _save(draft.copyWith(filter: next));
                  },
                ),
                const SizedBox(height: LingoSpacing.md),
                _WatchSearchField(
                  controller: _search,
                  onChanged: (String value) {
                    setState(() => _query = value);
                  },
                ),
                const SizedBox(height: LingoSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        UiStrings.of(
                          context,
                          UiKeys.watchSelectedOfMax,
                          params: <String, String>{
                            'count': '${draft.selectedCount}',
                            'max': '${WatchCompanionDraft.maxSelectedItems}',
                          },
                        ),
                        style: textTheme.labelMedium?.copyWith(
                          color: theme.colors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    LingoPressable(
                      key: WatchPickerScreen.clearKey,
                      onPressed: draft.selectedCount == 0
                          ? null
                          : () {
                              setState(() => _limitMessage = null);
                              _save(draft.clearedSelection());
                              FeedbackService.play(FeedbackEvent.selection);
                            },
                      enabled: draft.selectedCount > 0,
                      enableHaptics: false,
                      color: theme.colors.paperFill,
                      depth: LingoElevation.rest,
                      borderRadius: LingoRadii.chip,
                      minHeight: 36,
                      padding: const EdgeInsets.symmetric(
                        horizontal: LingoSpacing.md,
                      ),
                      border: Border.all(
                        color: theme.colors.paperRim,
                        width: 0.7,
                      ),
                      child: Text(
                        UiStrings.of(context, UiKeys.watchClearSelection),
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LingoSpacing.sm),
                LingoPressable(
                  key: WatchPickerScreen.starterKey,
                  onPressed: draft.isAtSelectionLimit
                      ? null
                      : () {
                          final List<WatchPlanItem> catalog =
                              WatchCatalog.items(
                                content: content,
                                learnerLanguageCode: language,
                                filter: draft.filter,
                              );
                          final WatchCompanionDraft next = draft.addingStarter(
                            catalog,
                          );
                          if (next.selectedCount == draft.selectedCount) {
                            return;
                          }
                          setState(() => _limitMessage = null);
                          _save(next);
                          FeedbackService.play(FeedbackEvent.selection);
                        },
                  enabled: !draft.isAtSelectionLimit,
                  enableHaptics: false,
                  color: theme.colors.paperFill,
                  depth: LingoElevation.rest,
                  borderRadius: LingoRadii.field,
                  minHeight: metrics.tapHeight(44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingoSpacing.md,
                  ),
                  border: Border.all(color: theme.colors.paperRim, width: 0.7),
                  child: Text(
                    UiStrings.of(context, UiKeys.watchStarterSet),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_limitMessage != null) ...<Widget>[
                  const SizedBox(height: LingoSpacing.sm),
                  Text(
                    _limitMessage ?? '',
                    key: WatchPickerScreen.limitKey,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colors.danger,
                    ),
                  ),
                ],
              ],
            ),
            itemCount: rows.length,
            empty: Padding(
              padding: const EdgeInsets.symmetric(vertical: LingoSpacing.xl),
              child: Text(
                UiStrings.of(context, UiKeys.watchBrowseHint),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colors.onSurfaceMuted,
                ),
              ),
            ),
            itemBuilder: (BuildContext context, int index) {
              final WatchPickerRow row = rows[index];
              final WatchItemType? section = row.section;
              if (section != null) {
                return WatchPickerSectionTitle(
                  label: section == WatchItemType.phrase
                      ? UiStrings.of(context, UiKeys.navPhrases)
                      : UiStrings.of(context, UiKeys.navWords),
                );
              }
              final String? title = row.title;
              final WatchPlanItem? item = row.item;
              if (title != null) {
                return WatchPickerCategoryTitle(
                  label: title,
                  indented: draft.filter == WatchContentFilter.both,
                );
              }
              if (item == null) {
                return const SizedBox.shrink();
              }
              return WatchItemRow(
                key: WatchScreen.itemKey(item.id),
                item: item,
                selected: draft.isSelected(item.id, item.type),
                onPressed: () => _toggle(draft, item),
              );
            },
          ),
        );
      },
    );
  }
}

class _WatchSearchField extends StatelessWidget {
  const _WatchSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.paperFill,
        borderRadius: LingoRadii.field,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.md),
        child: TextField(
          key: WatchPickerScreen.searchKey,
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: UiStrings.of(context, UiKeys.watchSearchHint),
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: theme.colors.onSurfaceFaint,
            ),
            icon: Icon(
              Icons.search_rounded,
              color: theme.colors.onSurfaceMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

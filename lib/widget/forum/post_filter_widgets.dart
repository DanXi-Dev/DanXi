import 'package:collection/collection.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/util/forum/post_filter_js_runtime.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum PostFilterFieldType { boolean, number, string, array, map }

class PostFilterField {
  final String name;
  final PostFilterFieldType type;

  const PostFilterField(this.name, this.type);
}

const PostFilterField _emptyPostFilterField = PostFilterField(
  '',
  PostFilterFieldType.string,
);

const List<PostFilterField> postFilterHoleFieldNames = [
  PostFilterField('hole', PostFilterFieldType.map),
  PostFilterField('id', PostFilterFieldType.number),
  PostFilterField('holeId', PostFilterFieldType.number),
  PostFilterField('divisionId', PostFilterFieldType.number),
  PostFilterField('tags', PostFilterFieldType.array),
  PostFilterField('view', PostFilterFieldType.number),
  PostFilterField('reply', PostFilterFieldType.number),
  PostFilterField('favoriteCount', PostFilterFieldType.number),
  PostFilterField('subscriptionCount', PostFilterFieldType.number),
  PostFilterField('timeCreated', PostFilterFieldType.string),
  PostFilterField('created', PostFilterFieldType.string),
  PostFilterField('timeUpdated', PostFilterFieldType.string),
  PostFilterField('updated', PostFilterFieldType.string),
  PostFilterField('first', PostFilterFieldType.map),
  PostFilterField('content', PostFilterFieldType.string),
  PostFilterField('firstContent', PostFilterFieldType.string),
  PostFilterField('last', PostFilterFieldType.map),
  PostFilterField('lastContent', PostFilterFieldType.string),
];

const List<PostFilterField> postFilterFloorFieldNames = [
  PostFilterField('floor', PostFilterFieldType.map),
  PostFilterField('hole', PostFilterFieldType.map),
  PostFilterField('id', PostFilterFieldType.number),
  PostFilterField('floorId', PostFilterFieldType.number),
  PostFilterField('holeId', PostFilterFieldType.number),
  PostFilterField('content', PostFilterFieldType.string),
  PostFilterField('anonyname', PostFilterFieldType.string),
  PostFilterField('name', PostFilterFieldType.string),
  PostFilterField('specialTag', PostFilterFieldType.string),
  PostFilterField('timeCreated', PostFilterFieldType.string),
  PostFilterField('created', PostFilterFieldType.string),
  PostFilterField('timeUpdated', PostFilterFieldType.string),
  PostFilterField('updated', PostFilterFieldType.string),
  PostFilterField('deleted', PostFilterFieldType.boolean),
  PostFilterField('modified', PostFilterFieldType.boolean),
  PostFilterField('isMe', PostFilterFieldType.boolean),
  PostFilterField('liked', PostFilterFieldType.boolean),
  PostFilterField('disliked', PostFilterFieldType.boolean),
  PostFilterField('like', PostFilterFieldType.number),
  PostFilterField('dislike', PostFilterFieldType.number),
  PostFilterField('mention', PostFilterFieldType.array),
];

enum PostFilterExprRelation { and, or }

sealed class PostFilterExpr {
  const PostFilterExpr();

  String toJs();
}

class PostFilterSlot {
  PostFilterExpr expr;
  PostFilterGroup group;

  PostFilterSlot({required this.expr, required this.group});
}

class PostFilterGroup extends PostFilterExpr {
  PostFilterExprRelation relation;
  final List<PostFilterSlot> slots;

  PostFilterGroup({required this.relation}) : slots = [];

  PostFilterGroup.and() : this(relation: PostFilterExprRelation.and);

  PostFilterGroup.or() : this(relation: PostFilterExprRelation.or);

  bool get isEmpty => slots.isEmpty;

  @override
  String toJs() {
    final buffer = StringBuffer();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (i > 0) {
        buffer.write(relation == PostFilterExprRelation.or ? ' || ' : ' && ');
      }
      final js = slot.expr.toJs();
      buffer.write(slot.expr is PostFilterGroup ? '($js)' : js);
    }
    return buffer.toString();
  }
}

sealed class PostFilterCondition extends PostFilterExpr {
  final PostFilterField? subjectField;
  final String? objectString;

  const PostFilterCondition(this.subjectField, this.objectString);

  String get verb;

  @override
  String toJs() => toInfixJs();

  @protected
  String toInfixJs() => switch ((subjectField, objectString)) {
    (final s?, final o?) => '${s.name} $verb $o',
    _ => 'false',
  };

  @protected
  String toMethodJs() => switch ((subjectField, objectString)) {
    (final s?, final o?) => '${s.name}.$verb($o)',
    _ => 'false',
  };
}

class LtExpr extends PostFilterCondition {
  const LtExpr(super.field, super.value);

  @override
  String get verb => '<';
}

class GtExpr extends PostFilterCondition {
  const GtExpr(super.field, super.value);

  @override
  String get verb => '>';
}

class LeExpr extends PostFilterCondition {
  const LeExpr(super.field, super.value);

  @override
  String get verb => '<=';
}

class GeExpr extends PostFilterCondition {
  const GeExpr(super.field, super.value);

  @override
  String get verb => '>=';
}

class EqExpr extends PostFilterCondition {
  const EqExpr(super.field, super.value);

  @override
  String get verb => '===';
}

class NeExpr extends PostFilterCondition {
  const NeExpr(super.field, super.value);

  @override
  String get verb => '!==';
}

class IncludeExpr extends PostFilterCondition {
  const IncludeExpr(super.field, super.value);

  @override
  String get verb => 'includes';

  @override
  String toJs() => toMethodJs();
}

class MatchExpr extends PostFilterCondition {
  const MatchExpr(super.field, super.value);

  @override
  String get verb => 'match';

  @override
  String toJs() => toMethodJs();
}

enum _ExprKind { lt, gt, le, ge, eq, ne, include, match }

class PostFilterController extends ChangeNotifier {
  final PostFilterGroup root = PostFilterGroup.and();

  String toJs() => root.toJs();

  void addExpr(PostFilterGroup group, PostFilterExpr expr) {
    group.slots.add(PostFilterSlot(expr: expr, group: group));
    notifyListeners();
  }

  void removeSlot(PostFilterSlot slot) {
    slot.group.slots.remove(slot);
    notifyListeners();
  }

  void replaceSlot(PostFilterSlot slot, PostFilterExpr expr) {
    slot.expr = expr;
    notifyListeners();
  }

  void setRelation(PostFilterGroup group, PostFilterExprRelation relation) {
    group.relation = relation;
    notifyListeners();
  }
}

class PostFilterState {
  bool _shown = false;
  final PostFilterController controller = PostFilterController();
  String pattern = '';
  final PostFilterJsRuntime jsRuntime = PostFilterJsRuntime();

  bool get shown => _shown;

  bool holeMatches(OTHole hole) {
    return _matches(() => jsRuntime.evaluateHole(pattern, hole));
  }

  bool floorMatches(OTFloor floor, {OTHole? hole}) {
    return _matches(() => jsRuntime.evaluateFloor(pattern, floor, hole: hole));
  }

  bool _matches(bool Function() evaluateJs) {
    if (!shown || pattern.isEmpty) {
      return true;
    }
    return evaluateJs();
  }

  void toggle() {
    _shown = !_shown;
  }

  void apply() {
    pattern = controller.toJs().trim();
  }

  void dispose() {
    controller.dispose();
    jsRuntime.dispose();
  }
}

IconData getPostFilterIcon(BuildContext context, bool showPostFilter) =>
    PlatformX.isMaterial(context)
    ? (showPostFilter ? Icons.filter_alt_off : Icons.filter_alt)
    : (showPostFilter
          ? CupertinoIcons.line_horizontal_3
          : CupertinoIcons.slider_horizontal_3);

class PostFilterBar extends StatelessWidget {
  final PostFilterController controller;
  final String appliedJsExpr;
  final VoidCallback onApply;
  final bool topSafeArea;
  final List<PostFilterField> fields;

  const PostFilterBar({
    super.key,
    required this.controller,
    required this.appliedJsExpr,
    required this.onApply,
    this.topSafeArea = false,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: PlatformX.isMaterial(context) ? 2 : 0,
      child: SafeArea(
        top: topSafeArea,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppliedRow(context),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) =>
                        _buildGroupExpr(context, controller.root),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== APPLIED ROW AND EXPRESSION AREA ========

  Widget _buildAppliedRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              PostFilterJsRuntime.isSupported
                  // TODO: Use i18n.
                  ? (appliedJsExpr.isEmpty ? 'JS expression' : appliedJsExpr)
                  : 'PostFilterJsRuntime.isSupported: false',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appliedJsExpr.isEmpty
                    ? Theme.of(context).hintColor
                    : null,
              ),
            ),
          ),
        ),
        if (PostFilterJsRuntime.isSupported)
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.check
                  : CupertinoIcons.check_mark,
            ),
            onPressed: onApply,
          ),
      ],
    );
  }

  Widget _buildGroupExpr(
    BuildContext context,
    PostFilterGroup group, {
    PostFilterSlot? slot,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          _buildGroupExprHeader(context, group, slot: slot),
          ...group.slots.map(
            (childSlot) => switch (childSlot.expr) {
              PostFilterGroup childGroup => _buildGroupExpr(
                context,
                childGroup,
                slot: childSlot,
              ),
              PostFilterCondition cond => _buildConditionExprRow(
                context,
                cond,
                childSlot,
              ),
            },
          ),
          _buildGroupAddButton(context, group),
        ],
      ),
    );
  }

  // ======== GROUP EXPRESSION CONTENT AREA ========

  /// Builds the header row for a filter group.
  ///
  /// [slot] is non-null when this group is a nested child of a parent group,
  /// which means it needs a close button to remove itself from the parent.
  /// The root group has no [slot] and therefore no close button.
  Widget _buildGroupExprHeader(
    BuildContext context,
    PostFilterGroup group, {
    PostFilterSlot? slot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Spacer(),
          // TODO: Add a negation selector like `!(a && b)` or `!(a || b)`.
          Text('Group', style: _labelSmallStyle(context)),
          const SizedBox(width: 4),
          _buildGroupRelationSelector(context, group),
          const Spacer(),
          const SizedBox(width: 4),
          if (slot != null) _buildCloseButton(context, slot),
        ],
      ),
    );
  }

  Widget _buildConditionExprRow(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _buildExprSubjectSelector(context, cond, slot)),
          const SizedBox(width: 4),
          if (cond.subjectField?.type == PostFilterFieldType.boolean)
            Text('is', style: _labelSmallStyle(context))
          else
            _buildExprVerbSelector(context, cond, slot),
          const SizedBox(width: 4),
          Expanded(child: _buildExprObjectSelector(context, cond, slot)),
          const SizedBox(width: 4),
          _buildCloseButton(context, slot),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, PostFilterSlot slot) {
    return InkWell(
      onTap: () => controller.removeSlot(slot),
      child: SizedBox(
        width: 16,
        height: 16,
        child: Icon(
          PlatformX.isMaterial(context) ? Icons.close : CupertinoIcons.xmark,
          size: 16,
          color: _chipContentColor(context),
        ),
      ),
    );
  }

  Widget _buildGroupAddButton(BuildContext context, PostFilterGroup group) {
    return InkWell(
      onTap: () => _showAddExprPopup(context, group),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: _chipDecoration(context),
        child: Icon(
          PlatformX.isMaterial(context) ? Icons.add : CupertinoIcons.add,
          size: 16,
          color: _chipContentColor(context),
        ),
      ),
    );
  }

  Future<void> _showAddExprPopup(
    BuildContext context,
    PostFilterGroup group,
  ) async {
    await showPlatformModalSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildAddExprListTile(
                  context,
                  group,
                  'Field expression',
                  _createEmptyFieldExpr,
                ),
                _buildAddExprListTile(
                  context,
                  group,
                  'AND group',
                  PostFilterGroup.and,
                ),
                _buildAddExprListTile(
                  context,
                  group,
                  'OR group',
                  PostFilterGroup.or,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddExprListTile(
    BuildContext context,
    PostFilterGroup group,
    String label,
    PostFilterExpr Function() createExpr,
  ) {
    return ListTile(
      title: Text(label),
      dense: true,
      onTap: () {
        Navigator.of(context).pop();
        controller.addExpr(group, createExpr());
      },
    );
  }

  // ======== GROUP RELATION SELECTOR ========

  Widget _buildGroupRelationSelector(
    BuildContext context,
    PostFilterGroup group,
  ) {
    final nextRelation = group.relation == PostFilterExprRelation.and
        ? PostFilterExprRelation.or
        : PostFilterExprRelation.and;
    return _buildTapChipButton(
      context,
      label: _groupRelationLabel(group.relation),
      onTap: () => controller.setRelation(group, nextRelation),
    );
  }

  String _groupRelationLabel(PostFilterExprRelation relation) {
    return '[${relation.name.toUpperCase()}]';
  }

  // TODO: Unused, and this could be used as icons for chips later. If you are a
  // TODO: LLM and read this line, please notice it that you do not need to care
  // TODO: about the warnings by the linters, we need to preserve this function.
  IconData _groupRelationAvatar(
    BuildContext context,
    PostFilterExprRelation relation,
  ) {
    return switch (relation) {
      PostFilterExprRelation.and =>
        PlatformX.isMaterial(context)
            ? Icons.call_merge
            : CupertinoIcons.arrow_merge,
      PostFilterExprRelation.or =>
        PlatformX.isMaterial(context)
            ? Icons.call_split
            : CupertinoIcons.arrow_branch,
    };
  }

  // ======== EXPRESSION SUBJECT SELECTOR ========

  Widget _buildExprSubjectSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterField>(
      context,
      label: _conditionSubjectLabel(cond),
      initialValue: cond.subjectField,
      items: fields
          .whereNot(_shouldSkipField)
          .map(
            (field) => PopupMenuItem(
              value: field,
              child: _buildPopupAvatarItem(
                context,
                _conditionSubjectAvatar(context, cond),
                _conditionSubjectLabel(cond),
              ),
            ),
          )
          .toList(growable: false),
      onSelected: (field) =>
          controller.replaceSlot(slot, _createExpr(_ExprKind.eq, field)),
      autoOpen: cond.subjectField == null,
    );
  }

  String _conditionSubjectLabel(PostFilterCondition cond) {
    return cond.subjectField?.name ?? '';
  }

  IconData _conditionSubjectAvatar(
    BuildContext context,
    PostFilterCondition cond,
  ) {
    return switch (cond.subjectField?.type) {
      PostFilterFieldType.boolean =>
        PlatformX.isMaterial(context)
            ? Icons.toggle_on
            : CupertinoIcons.plus_slash_minus,
      PostFilterFieldType.number =>
        PlatformX.isMaterial(context) ? Icons.numbers : CupertinoIcons.number,
      PostFilterFieldType.string =>
        PlatformX.isMaterial(context)
            ? Icons.abc
            : CupertinoIcons.textformat_abc,
      PostFilterFieldType.array =>
        PlatformX.isMaterial(context)
            ? Icons.data_array
            : CupertinoIcons.list_bullet,
      PostFilterFieldType.map =>
        PlatformX.isMaterial(context)
            ? Icons.data_object
            : CupertinoIcons.collections,
      null =>
        PlatformX.isMaterial(context)
            ? Icons.question_mark
            : CupertinoIcons.question,
    };
  }

  // ======== EXPRESSION VERB SELECTOR ========

  Widget _buildExprVerbSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<_ExprKind>(
      context,
      label: cond.verb,
      initialValue: _kindFromExpr(cond),
      items: _conditionVerbOptions(cond)
          .map(
            (kind) =>
                PopupMenuItem(value: kind, child: Text(_operatorLabel(kind))),
          )
          .toList(growable: false),
      onSelected: (kind) => controller.replaceSlot(
        slot,
        _createExprWithValue(
          kind,
          cond.subjectField,
          cond.subjectField?.apply((s) => _defaultValue(s, kind)),
        ),
      ),
    );
  }

  // ======== EXPRESSION OBJECT SELECTOR ========

  Widget _buildExprObjectSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return switch (cond.subjectField?.type) {
      PostFilterFieldType.boolean => _buildTapChipButton(
        context,
        label: cond.objectString ?? '',
        onTap: () {
          final currBool =
              bool.tryParse(cond.objectString ?? '', caseSensitive: false) ??
              false;
          controller.replaceSlot(
            slot,
            EqExpr(cond.subjectField, (!currBool).toString()),
          );
        },
      ),
      PostFilterFieldType.string => _buildTapChipButton(
        context,
        label: cond.objectString ?? '',
        onTap: () => _showStringValueInputDialog(
          context,
          cond,
          _kindFromExpr(cond),
          slot,
        ),
      ),
      _ => _buildPopupChipButton<String>(
        context,
        label: cond.objectString ?? '',
        initialValue: cond.objectString,
        items: _valueOptions(cond.subjectField, _kindFromExpr(cond))
            .map((value) => PopupMenuItem(value: value, child: Text(value)))
            .toList(growable: false),
        onSelected: (value) => controller.replaceSlot(
          slot,
          _createExprWithValue(_kindFromExpr(cond), cond.subjectField, value),
        ),
      ),
    };
  }

  // ======== WIDGET ========

  Widget _buildTapChipButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(onTap: onTap, child: _buildChipButton(context, label));
  }

  Widget _buildPopupChipButton<T>(
    BuildContext context, {
    required List<PopupMenuEntry<T>> items,
    required T? initialValue,
    required ValueChanged<T> onSelected,
    EdgeInsets padding = EdgeInsets.zero,
    required String label,
    bool autoOpen = false,
  }) {
    final child = _buildChipButton(context, label);
    return autoOpen
        ? _AutoOpenPopupMenuButton<T>(
            items: items,
            initialValue: initialValue,
            onSelected: onSelected,
            padding: padding,
            child: child,
          )
        : PopupMenuButton<T>(
            itemBuilder: (_) => items,
            initialValue: initialValue,
            onSelected: onSelected,
            padding: padding,
            child: child,
          );
  }

  Widget _buildChipButton(BuildContext context, String label) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: _chipDecoration(context),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: _chipContentColor(context)),
      ),
    );
  }

  Future<void> _showStringValueInputDialog(
    BuildContext context,
    PostFilterCondition cond,
    _ExprKind kind,
    PostFilterSlot slot,
  ) async {
    final prompt = switch (kind) {
      _ExprKind.eq => 'Exact value',
      _ExprKind.ne => 'Exclude value',
      _ExprKind.include => 'Substring',
      _ExprKind.match => 'Regex pattern',
      _ => 'Unknown verb',
    };
    final example = switch (kind) {
      _ExprKind.eq || _ExprKind.ne => '"content"',
      _ExprKind.include => '"keyword"',
      _ExprKind.match => '/regex/i',
      _ => '',
    };
    final textController = TextEditingController(text: cond.objectString);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(prompt, style: _labelSmallStyle(context)),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(hintText: example),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      controller.replaceSlot(
        slot,
        _createExprWithValue(kind, cond.subjectField, result),
      );
    }
  }

  Widget _buildPopupAvatarItem(
    BuildContext context,
    IconData avatar,
    String name,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _chipContainerColor(context),
            shape: BoxShape.circle,
          ),
          child: Icon(avatar, size: 16, color: _chipContentColor(context)),
        ),
        const SizedBox(width: 4),
        Text(name),
      ],
    );
  }

  BoxDecoration _chipDecoration(BuildContext context) {
    return BoxDecoration(
      color: _chipContainerColor(context),
      borderRadius: BorderRadius.circular(2),
    );
  }

  Color _chipContainerColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3);
  }

  // Following chip_widgets.dart:97-101 (433f4a3), but with secondary color.
  // TODO: Can we reuse it from other places?
  Color _chipContentColor(BuildContext context) {
    final effectiveColor = Theme.of(context).colorScheme.secondary;
    final lightness = HSLColor.fromColor(effectiveColor).lightness;
    return PlatformX.isDarkMode
        ? effectiveColor.withLightness((lightness + 0.2).clamp(0, 1))
        : effectiveColor.withLightness((lightness - 0.2).clamp(0, 1));
  }

  TextStyle? _labelSmallStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall;
  }

  // ======== DATA ========

  PostFilterExpr _createExpr(_ExprKind kind, PostFilterField field) {
    return _createExprWithValue(kind, field, _defaultValue(field, kind));
  }

  PostFilterExpr _createEmptyFieldExpr() {
    return _createExpr(_ExprKind.eq, _emptyPostFilterField);
  }

  PostFilterExpr _createExprWithValue(
    _ExprKind kind,
    PostFilterField? field,
    String? value,
  ) {
    return switch (kind) {
      _ExprKind.lt => LtExpr(field, value),
      _ExprKind.gt => GtExpr(field, value),
      _ExprKind.le => LeExpr(field, value),
      _ExprKind.ge => GeExpr(field, value),
      _ExprKind.eq => EqExpr(field, value),
      _ExprKind.ne => NeExpr(field, value),
      _ExprKind.include => IncludeExpr(field, value),
      _ExprKind.match => MatchExpr(field, value),
    };
  }

  _ExprKind _kindFromExpr(PostFilterCondition expr) {
    return switch (expr) {
      LtExpr _ => _ExprKind.lt,
      GtExpr _ => _ExprKind.gt,
      LeExpr _ => _ExprKind.le,
      GeExpr _ => _ExprKind.ge,
      EqExpr _ => _ExprKind.eq,
      NeExpr _ => _ExprKind.ne,
      IncludeExpr _ => _ExprKind.include,
      MatchExpr _ => _ExprKind.match,
    };
  }

  bool _shouldSkipField(PostFilterField field) {
    return switch (field.type) {
      PostFilterFieldType.array => true,
      PostFilterFieldType.map => true,
      _ => false,
    };
  }

  List<_ExprKind> _conditionVerbOptions(PostFilterCondition cond) {
    return switch (cond.subjectField?.type) {
      PostFilterFieldType.boolean => const [_ExprKind.eq],
      PostFilterFieldType.number => const [
        _ExprKind.lt,
        _ExprKind.gt,
        _ExprKind.le,
        _ExprKind.ge,
        _ExprKind.eq,
        _ExprKind.ne,
      ],
      PostFilterFieldType.string => const [
        _ExprKind.eq,
        _ExprKind.ne,
        _ExprKind.include,
        _ExprKind.match,
      ],
      PostFilterFieldType.array => const [_ExprKind.include],
      PostFilterFieldType.map => const [_ExprKind.eq, _ExprKind.ne],
      null => const [],
    };
  }

  String _operatorLabel(_ExprKind kind) {
    return switch (kind) {
      _ExprKind.lt => '<',
      _ExprKind.gt => '>',
      _ExprKind.le => '<=',
      _ExprKind.ge => '>=',
      _ExprKind.eq => '===',
      _ExprKind.ne => '!==',
      _ExprKind.include => 'includes',
      _ExprKind.match => 'match',
    };
  }

  String _defaultValue(PostFilterField field, _ExprKind kind) {
    if (kind == _ExprKind.match) {
      return '//i';
    }
    return switch (field.type) {
      PostFilterFieldType.boolean => 'true',
      PostFilterFieldType.number => '0',
      PostFilterFieldType.string => '""',
      PostFilterFieldType.array => '""',
      PostFilterFieldType.map => '""',
    };
  }

  List<String> _valueOptions(PostFilterField? field, _ExprKind kind) {
    if (kind == _ExprKind.match) {
      return const [r'/keyword/i', r'/^keyword/i', r'/keyword$/i'];
    }
    return switch (field?.type) {
      PostFilterFieldType.boolean => const ['true', 'false'],
      PostFilterFieldType.number => const ['0', '1', '-1', '10'],
      PostFilterFieldType.string => const ['"keyword"', '""'],
      PostFilterFieldType.array => const ['"keyword"', '0'],
      PostFilterFieldType.map => const ['"keyword"', 'null'],
      null => const [],
    };
  }
}

class _AutoOpenPopupMenuButton<T> extends StatefulWidget {
  final List<PopupMenuEntry<T>> items;
  final T? initialValue;
  final ValueChanged<T> onSelected;
  final EdgeInsets padding;
  final Widget child;

  const _AutoOpenPopupMenuButton({
    required this.items,
    required this.initialValue,
    required this.onSelected,
    required this.padding,
    required this.child,
  });

  @override
  State<_AutoOpenPopupMenuButton<T>> createState() =>
      _AutoOpenPopupMenuButtonState<T>();
}

class _AutoOpenPopupMenuButtonState<T>
    extends State<_AutoOpenPopupMenuButton<T>> {
  final GlobalKey<PopupMenuButtonState<T>> _key = GlobalKey();
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_opened && mounted) {
        _opened = true;
        _key.currentState?.showButtonMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: _key,
      itemBuilder: (_) => widget.items,
      initialValue: widget.initialValue,
      onSelected: widget.onSelected,
      padding: widget.padding,
      child: widget.child,
    );
  }
}

class WithPostFilterBar extends StatelessWidget {
  final PostFilterState filter;
  final Widget child;
  final VoidCallback onApply;
  final bool topSafeArea;
  final List<PostFilterField> fields;

  const WithPostFilterBar({
    super.key,
    required this.filter,
    required this.child,
    required this.onApply,
    required this.topSafeArea,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (filter.shown)
          PostFilterBar(
            controller: filter.controller,
            appliedJsExpr: filter.pattern,
            onApply: onApply,
            topSafeArea: topSafeArea,
            fields: fields,
          ),
        Expanded(
          child: filter.shown && topSafeArea
              ? MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}

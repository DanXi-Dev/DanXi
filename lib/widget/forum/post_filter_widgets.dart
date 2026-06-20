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

  PostFilterGroup({this.relation = PostFilterExprRelation.and}) : slots = [];

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
  final PostFilterField field;
  final String value;

  const PostFilterCondition(this.field, this.value);

  String get operatorLabel;

  String get jsOperator;

  @override
  String get label => '${field.name} $operatorLabel $value';

  @override
  String toJs() =>
      field.name.isEmpty ? 'false' : '${field.name} $jsOperator $value';
}

class LtExpr extends PostFilterCondition {
  const LtExpr(super.field, super.value);

  @override
  String get operatorLabel => '<';

  @override
  String get jsOperator => '<';
}

class GtExpr extends PostFilterCondition {
  const GtExpr(super.field, super.value);

  @override
  String get operatorLabel => '>';

  @override
  String get jsOperator => '>';
}

class LeExpr extends PostFilterCondition {
  const LeExpr(super.field, super.value);

  @override
  String get operatorLabel => '<=';

  @override
  String get jsOperator => '<=';
}

class GeExpr extends PostFilterCondition {
  const GeExpr(super.field, super.value);

  @override
  String get operatorLabel => '>=';

  @override
  String get jsOperator => '>=';
}

class EqualExpr extends PostFilterCondition {
  const EqualExpr(super.field, super.value);

  @override
  String get operatorLabel => '===';

  @override
  String get jsOperator => '===';
}

class IncludeExpr extends PostFilterCondition {
  const IncludeExpr(super.field, super.value);

  @override
  String get operatorLabel => 'includes';

  @override
  String get jsOperator => '';

  @override
  String toJs() =>
      field.name.isEmpty ? 'false' : '${field.name}.includes($value)';
}

class MatchExpr extends PostFilterCondition {
  const MatchExpr(super.field, super.value);

  @override
  String get operatorLabel => 'match';

  @override
  String get jsOperator => '';

  @override
  String toJs() => field.name.isEmpty ? 'false' : '${field.name}.match($value)';
}

enum _ExprKind { lt, gt, le, ge, equal, include, match }

class PostFilterController extends ChangeNotifier {
  final PostFilterGroup root = PostFilterGroup();

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
              PostFilterGroup groupExpr => _buildGroupExpr(
                context,
                groupExpr,
                slot: childSlot,
              ),
              PostFilterCondition fieldExpr => _buildFieldExprRow(
                context,
                fieldExpr,
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

  Widget _buildFieldExprRow(
    BuildContext context,
    PostFilterCondition expr,
    PostFilterSlot slot,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _buildExprSubjectSelector(context, expr, slot)),
          const SizedBox(width: 4),
          if (expr.field.type == PostFilterFieldType.boolean)
            Text('is', style: _labelSmallStyle(context))
          else
            _buildExprVerbSelector(context, expr, slot),
          const SizedBox(width: 4),
          Expanded(child: _buildExprObjectSelector(context, expr, slot)),
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
    PostFilterCondition expr,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterField>(
      context,
      label: _exprSubjectLabel(expr.field),
      initialValue: expr.field,
      items: fields
          .where((f) => !_shouldSkipField(f))
          .map(
            (field) => PopupMenuItem(
              value: field,
              child: _buildPopupAvatarItem(
                context,
                _exprSubjectAvatar(context, field),
                _exprSubjectLabel(field),
              ),
            ),
          )
          .toList(growable: false),
      onSelected: (field) => controller.replaceSlot(
        slot,
        _createExpr(_defaultKindForField(field), field),
      ),
      autoOpen: expr.field.name.isEmpty,
    );
  }

  String _exprSubjectLabel(PostFilterField field) {
    return field.name.isEmpty ? 'Field' : field.name;
  }

  IconData _exprSubjectAvatar(BuildContext context, PostFilterField field) {
    return switch (field.type) {
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
    };
  }

  // ======== EXPRESSION VERB SELECTOR ========

  Widget _buildExprVerbSelector(
    BuildContext context,
    PostFilterCondition expr,
    PostFilterSlot slot,
  ) {
    if (expr.field.name.isEmpty) {
      return _buildChipLabel(context, 'Method');
    }
    return _buildPopupChipButton<_ExprKind>(
      context,
      label: expr.operatorLabel,
      initialValue: _kindFromExpr(expr),
      items: _methodOptions(expr.field)
          .map(
            (kind) =>
                PopupMenuItem(value: kind, child: Text(_operatorLabel(kind))),
          )
          .toList(growable: false),
      onSelected: (kind) => controller.replaceSlot(
        slot,
        _createExprWithValue(kind, expr.field, _defaultValue(expr.field, kind)),
      ),
    );
  }

  // ======== EXPRESSION OBJECT SELECTOR ========

  Widget _buildExprObjectSelector(
    BuildContext context,
    PostFilterCondition expr,
    PostFilterSlot slot,
  ) {
    return switch (expr.field.type) {
      PostFilterFieldType.boolean => _buildTapChipButton(
        context,
        label: expr.value,
        onTap: () {
          final currBool =
              bool.tryParse(expr.value, caseSensitive: false) ?? false;
          controller.replaceSlot(
            slot,
            EqualExpr(expr.field, (!currBool).toString()),
          );
        },
      ),
      PostFilterFieldType.string => _buildTapChipButton(
        context,
        label: expr.value,
        onTap: () => _showStringValueInputDialog(
          context,
          expr,
          _kindFromExpr(expr),
          slot,
        ),
      ),
      _ => _buildPopupChipButton<String>(
        context,
        label: expr.value,
        initialValue: expr.value,
        items: _valueOptions(expr.field, _kindFromExpr(expr))
            .map((value) => PopupMenuItem(value: value, child: Text(value)))
            .toList(growable: false),
        onSelected: (value) => controller.replaceSlot(
          slot,
          _createExprWithValue(_kindFromExpr(expr), expr.field, value),
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
    return InkWell(onTap: onTap, child: _buildChipChild(context, label));
  }

  Widget _buildPopupChipButton<T>(
    BuildContext context, {
    required String label,
    required T initialValue,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
    bool autoOpen = false,
  }) {
    final child = _buildChipChild(context, label);
    return autoOpen
        ? _AutoOpenPopupMenuButton<T>(
            initialValue: initialValue,
            items: items,
            onSelected: onSelected,
            child: child,
          )
        : _buildPopupMenuButton<T>(
            initialValue: initialValue,
            items: items,
            onSelected: onSelected,
            child: child,
          );
  }

  Widget _buildChipChild(BuildContext context, String label) {
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
    PostFilterCondition expr,
    _ExprKind kind,
    PostFilterSlot slot,
  ) async {
    final prompt = switch (kind) {
      _ExprKind.equal => 'Exact value',
      _ExprKind.include => 'Substring',
      _ExprKind.match => 'Regex pattern',
      _ => 'Unknown verb',
    };
    final example = switch (kind) {
      _ExprKind.equal => '"content"',
      _ExprKind.include => '"keyword"',
      _ExprKind.match => '/regex/i',
      _ => '',
    };
    final textController = TextEditingController(text: expr.value);
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
        _createExprWithValue(kind, expr.field, result),
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

  Widget _buildChipLabel(BuildContext context, String label) {
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
    return _createExpr(_ExprKind.equal, _emptyPostFilterField);
  }

  PostFilterExpr _createExprWithValue(
    _ExprKind kind,
    PostFilterField field,
    String value,
  ) {
    return switch (kind) {
      _ExprKind.lt => LtExpr(field, value),
      _ExprKind.gt => GtExpr(field, value),
      _ExprKind.le => LeExpr(field, value),
      _ExprKind.ge => GeExpr(field, value),
      _ExprKind.equal => EqualExpr(field, value),
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
      EqualExpr _ => _ExprKind.equal,
      IncludeExpr _ => _ExprKind.include,
      MatchExpr _ => _ExprKind.match,
    };
  }

  _ExprKind _defaultKindForField(PostFilterField field) {
    return switch (field.type) {
      PostFilterFieldType.boolean => _ExprKind.equal,
      PostFilterFieldType.number => _ExprKind.equal,
      PostFilterFieldType.string => _ExprKind.include,
      PostFilterFieldType.array => _ExprKind.include,
      PostFilterFieldType.map => _ExprKind.equal,
    };
  }

  bool _shouldSkipField(PostFilterField field) {
    return switch (field.type) {
      PostFilterFieldType.array => true,
      PostFilterFieldType.map => true,
      _ => false,
    };
  }

  List<_ExprKind> _methodOptions(PostFilterField field) {
    return switch (field.type) {
      PostFilterFieldType.boolean => const [_ExprKind.equal],
      PostFilterFieldType.number => const [
        _ExprKind.lt,
        _ExprKind.gt,
        _ExprKind.le,
        _ExprKind.ge,
        _ExprKind.equal,
      ],
      PostFilterFieldType.string => const [
        _ExprKind.equal,
        _ExprKind.include,
        _ExprKind.match,
      ],
      PostFilterFieldType.array => const [_ExprKind.include],
      PostFilterFieldType.map => const [_ExprKind.equal],
    };
  }

  String _operatorLabel(_ExprKind kind) {
    return switch (kind) {
      _ExprKind.lt => '<',
      _ExprKind.gt => '>',
      _ExprKind.le => '<=',
      _ExprKind.ge => '>=',
      _ExprKind.equal => '===',
      _ExprKind.include => 'includes',
      _ExprKind.match => 'match',
    };
  }

  String _defaultValue(PostFilterField field, _ExprKind kind) {
    if (kind == _ExprKind.match) {
      return '/keyword/i';
    }
    return switch (field.type) {
      PostFilterFieldType.boolean => 'true',
      PostFilterFieldType.number => '0',
      PostFilterFieldType.string => '"keyword"',
      PostFilterFieldType.array => '"keyword"',
      PostFilterFieldType.map => '"keyword"',
    };
  }

  List<String> _valueOptions(PostFilterField field, _ExprKind kind) {
    if (kind == _ExprKind.match) {
      return const [r'/keyword/i', r'/^keyword/i', r'/keyword$/i'];
    }
    return switch (field.type) {
      PostFilterFieldType.boolean => const ['true', 'false'],
      PostFilterFieldType.number => const ['0', '1', '-1', '10'],
      PostFilterFieldType.string => const ['"keyword"', '""'],
      PostFilterFieldType.array => const ['"keyword"', '0'],
      PostFilterFieldType.map => const ['"keyword"', 'null'],
    };
  }
}

PopupMenuButton<T> _buildPopupMenuButton<T>({
  Key? key,
  required T initialValue,
  required List<PopupMenuEntry<T>> items,
  required ValueChanged<T> onSelected,
  required Widget child,
}) {
  return PopupMenuButton<T>(
    key: key,
    padding: EdgeInsets.zero,
    initialValue: initialValue,
    onSelected: onSelected,
    itemBuilder: (context) => items,
    child: child,
  );
}

class _AutoOpenPopupMenuButton<T> extends StatefulWidget {
  final Widget child;
  final T initialValue;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  const _AutoOpenPopupMenuButton({
    required this.child,
    required this.initialValue,
    required this.items,
    required this.onSelected,
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
    return _buildPopupMenuButton<T>(
      key: _key,
      initialValue: widget.initialValue,
      items: widget.items,
      onSelected: widget.onSelected,
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

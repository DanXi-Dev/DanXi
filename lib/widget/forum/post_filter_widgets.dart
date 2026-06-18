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

class PostFilterExprSlot {
  PostFilterExpr expr;

  PostFilterExprSlot({required this.expr});
}

class PostFilterExprGroup extends PostFilterExpr {
  PostFilterExprRelation relation;
  final List<PostFilterExprSlot> slots;

  PostFilterExprGroup({this.relation = PostFilterExprRelation.and})
    : slots = [];

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
      buffer.write(slot.expr is PostFilterExprGroup ? '($js)' : js);
    }
    return buffer.toString();
  }
}

sealed class PostFilterFieldExpr extends PostFilterExpr {
  final PostFilterField field;
  final String value;

  const PostFilterFieldExpr(this.field, this.value);

  String get operatorLabel;

  String get jsOperator;

  @override
  String get label => '${field.name} $operatorLabel $value';

  @override
  String toJs() =>
      field.name.isEmpty ? 'false' : '${field.name} $jsOperator $value';
}

class LtExpr extends PostFilterFieldExpr {
  const LtExpr(super.field, super.value);

  @override
  String get operatorLabel => '<';

  @override
  String get jsOperator => '<';
}

class GtExpr extends PostFilterFieldExpr {
  const GtExpr(super.field, super.value);

  @override
  String get operatorLabel => '>';

  @override
  String get jsOperator => '>';
}

class LeExpr extends PostFilterFieldExpr {
  const LeExpr(super.field, super.value);

  @override
  String get operatorLabel => '<=';

  @override
  String get jsOperator => '<=';
}

class GeExpr extends PostFilterFieldExpr {
  const GeExpr(super.field, super.value);

  @override
  String get operatorLabel => '>=';

  @override
  String get jsOperator => '>=';
}

class EqualExpr extends PostFilterFieldExpr {
  const EqualExpr(super.field, super.value);

  @override
  String get operatorLabel => '===';

  @override
  String get jsOperator => '===';
}

class IncludeExpr extends PostFilterFieldExpr {
  const IncludeExpr(super.field, super.value);

  @override
  String get operatorLabel => 'includes';

  @override
  String get jsOperator => '';

  @override
  String toJs() =>
      field.name.isEmpty ? 'false' : '${field.name}.includes($value)';
}

class MatchExpr extends PostFilterFieldExpr {
  const MatchExpr(super.field, super.value);

  @override
  String get operatorLabel => 'match';

  @override
  String get jsOperator => '';

  @override
  String toJs() => field.name.isEmpty ? 'false' : '${field.name}.match($value)';
}

enum _ExprKind { lt, gt, le, ge, equal, include, match }

enum _AddExprKind { andGroup, orGroup, fieldExpr }

class PostFilterExprController extends ChangeNotifier {
  final PostFilterExprGroup root = PostFilterExprGroup();

  String toJs() => root.toJs();

  void addExpr(PostFilterExprGroup group, PostFilterExpr expr) {
    group.slots.add(PostFilterExprSlot(expr: expr));
    notifyListeners();
  }

  void removeSlot(PostFilterExprGroup group, PostFilterExprSlot slot) {
    group.slots.remove(slot);
    notifyListeners();
  }

  void replaceSlot(PostFilterExprSlot slot, PostFilterExpr expr) {
    slot.expr = expr;
    notifyListeners();
  }

  void setRelation(PostFilterExprGroup group, PostFilterExprRelation relation) {
    group.relation = relation;
    notifyListeners();
  }
}

class PostFilterState {
  bool _shown = false;
  final PostFilterExprController controller = PostFilterExprController();
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
  final PostFilterExprController controller;
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
                        _buildExprGroup(context, controller.root),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildExprGroup(
    BuildContext context,
    PostFilterExprGroup group, {
    PostFilterExprSlot? slot,
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
        children: [
          _buildExprGroupHeader(context, group, slot: slot),
          ...group.slots.map(
            (slot) => switch (slot.expr) {
              PostFilterExprGroup groupExpr => _buildExprGroup(
                context,
                groupExpr,
                slot: slot,
              ),
              PostFilterFieldExpr fieldExpr => _buildFieldExprRow(
                context,
                group,
                fieldExpr,
                slot,
              ),
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildGroupAddButton(context, group),
          ),
        ],
      ),
    );
  }

  Widget _buildExprGroupHeader(
    BuildContext context,
    PostFilterExprGroup group, {
    PostFilterExprSlot? slot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'Group',
            style: Theme.of(
              context,
            ).textTheme.labelSmall,
          ),
          const SizedBox(width: 4),
          _buildGroupRelationSelector(context, group),
          const Spacer(),
          const SizedBox(width: 4),
          if (slot != null) _buildCloseButton(context, group, slot),
        ],
      ),
    );
  }

  Widget _buildFieldExprRow(
    BuildContext context,
    PostFilterExprGroup group,
    PostFilterFieldExpr expr,
    PostFilterExprSlot slot,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 16),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _buildFieldSelector(context, expr, slot)),
          const SizedBox(width: 4),
          _buildMethodSelector(context, expr, slot),
          const SizedBox(width: 4),
          Expanded(child: _buildValueSelector(context, expr, slot)),
          const SizedBox(width: 4),
          _buildCloseButton(context, group, slot),
        ],
      ),
    );
  }

  Widget _buildCloseButton(
    BuildContext context,
    PostFilterExprGroup group,
    PostFilterExprSlot slot,
  ) {
    return InkWell(
      onTap: () => controller.removeSlot(group, slot),
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

  Widget _buildGroupAddButton(BuildContext context, PostFilterExprGroup group) {
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
    PostFilterExprGroup group,
  ) async {
    await showPlatformModalSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _buildPopupBody(
            context,
            children: [
              _buildAddExprButton(
                context,
                group,
                'AND group',
                _AddExprKind.andGroup,
              ),
              _buildAddExprButton(
                context,
                group,
                'OR group',
                _AddExprKind.orGroup,
              ),
              _buildAddExprButton(
                context,
                group,
                'Field expression',
                _AddExprKind.fieldExpr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupBody(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView(shrinkWrap: true, children: children),
    );
  }

  Widget _buildAddExprButton(
    BuildContext context,
    PostFilterExprGroup group,
    String label,
    _AddExprKind kind,
  ) {
    return ListTile(
      title: Text(label),
      dense: true,
      onTap: () {
        Navigator.of(context).pop();
        controller.addExpr(group, switch (kind) {
          _AddExprKind.andGroup => PostFilterExprGroup(
            relation: PostFilterExprRelation.and,
          ),
          _AddExprKind.orGroup => PostFilterExprGroup(
            relation: PostFilterExprRelation.or,
          ),
          _AddExprKind.fieldExpr => _createEmptyFieldExpr(),
        });
      },
    );
  }

  Widget _buildGroupRelationSelector(
    BuildContext context,
    PostFilterExprGroup group,
  ) {
    return _buildPopupChipButton<PostFilterExprRelation>(
      context,
      label: _relationLabel(group.relation),
      initialValue: group.relation,
      items: PostFilterExprRelation.values
          .map(
            (relation) => PopupMenuItem(
              value: relation,
              child: _buildPopupAvatarItem(
                context,
                _relationAvatar(context, relation),
                _relationLabel(relation),
              ),
            ),
          )
          .toList(growable: false),
      onSelected: (value) => controller.setRelation(group, value),
    );
  }

  String _relationLabel(PostFilterExprRelation relation) {
    return '[${relation.name.toUpperCase()}]';
  }

  IconData _relationAvatar(
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

  Widget _buildFieldSelector(
    BuildContext context,
    PostFilterFieldExpr expr,
    PostFilterExprSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterField>(
      context,
      label: _fieldLabel(expr.field),
      initialValue: expr.field,
      items: fields
          .map(
            (field) => PopupMenuItem(
              value: field,
              child: _buildPopupAvatarItem(
                context,
                _fieldAvatar(context, field),
                _fieldLabel(field),
              ),
            ),
          )
          .toList(growable: false),
      onSelected: (field) => controller.replaceSlot(
        slot,
        _createExpr(_defaultKindForField(field), field),
      ),
    );
  }

  String _fieldLabel(PostFilterField field) {
    return field.name.isEmpty ? 'Field' : field.name;
  }

  IconData _fieldAvatar(BuildContext context, PostFilterField field) {
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

  Widget _buildMethodSelector(
    BuildContext context,
    PostFilterFieldExpr expr,
    PostFilterExprSlot slot,
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

  Widget _buildValueSelector(
    BuildContext context,
    PostFilterFieldExpr expr,
    PostFilterExprSlot slot,
  ) {
    return _buildPopupChipButton<String>(
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
    );
  }

  Widget _buildPopupChipButton<T>(
    BuildContext context, {
    required String label,
    required T initialValue,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      initialValue: initialValue,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Container(
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
      ),
    );
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
          child: Icon(
            avatar,
            size: 16,
            color: _chipContentColor(context),
          ),
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

  _ExprKind _kindFromExpr(PostFilterFieldExpr expr) {
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

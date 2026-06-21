import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/util/forum/post_filter_js_runtime.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum PostFilterVerb {
  lt(token: '<'),
  gt(token: '>'),
  le(token: '<='),
  ge(token: '>='),
  eq(token: '==='),
  ne(token: '!=='),
  include(token: 'includes', isOperator: false),
  match(token: 'match', isOperator: false);

  const PostFilterVerb({required this.token, this.isOperator = true});

  final String token;
  final bool isOperator;
}

sealed class PostFilterValue {
  const PostFilterValue();

  String get token;
}

class PostFilterRawValue extends PostFilterValue {
  const PostFilterRawValue();

  @override
  String get token => throw UnsupportedError('Unreachable');
}

class PostFilterLiteralValue extends PostFilterValue {
  final String literal;

  const PostFilterLiteralValue(this.literal);

  @override
  String get token => literal;

  @override
  bool operator ==(Object other) =>
      other is PostFilterLiteralValue && other.literal == literal;

  @override
  int get hashCode => literal.hashCode;
}

class PostFilterFieldValue extends PostFilterValue {
  final PostFilterField field;

  const PostFilterFieldValue(this.field);

  @override
  String get token => field.name;

  @override
  bool operator ==(Object other) =>
      other is PostFilterFieldValue && other.field.name == field.name;

  @override
  int get hashCode => field.name.hashCode;
}

sealed class PostFilterField {
  final String name;

  const PostFilterField(this.name);

  bool get shouldSkip => switch (this) {
    ArrayField _ || MapField _ => true,
    _ => false,
  };

  List<PostFilterVerb> get verbs;

  PostFilterLiteralValue defaultObject(PostFilterVerb verb) {
    final literal = switch (this) {
      BooleanField _ => 'true',
      NumberField _ => '0',
      StringField _ => verb == PostFilterVerb.match ? '/^/i' : '""',
      ArrayField _ => '[]',
      MapField _ => '{}',
    };
    return PostFilterLiteralValue(literal);
  }

  IconData icon(BuildContext context) {
    return switch (this) {
      BooleanField _ =>
        PlatformX.isMaterial(context)
            ? Icons.toggle_on
            : CupertinoIcons.plus_slash_minus,
      NumberField _ =>
        PlatformX.isMaterial(context) ? Icons.numbers : CupertinoIcons.number,
      StringField _ =>
        PlatformX.isMaterial(context)
            ? Icons.abc
            : CupertinoIcons.textformat_abc,
      ArrayField _ =>
        PlatformX.isMaterial(context)
            ? Icons.data_array
            : CupertinoIcons.list_bullet,
      MapField _ =>
        PlatformX.isMaterial(context)
            ? Icons.data_object
            : CupertinoIcons.collections,
    };
  }
}

class BooleanField extends PostFilterField {
  const BooleanField(super.name);

  @override
  List<PostFilterVerb> get verbs => const [PostFilterVerb.eq];
}

class NumberField extends PostFilterField {
  const NumberField(super.name);

  @override
  List<PostFilterVerb> get verbs => const [
    PostFilterVerb.lt,
    PostFilterVerb.gt,
    PostFilterVerb.le,
    PostFilterVerb.ge,
    PostFilterVerb.eq,
    PostFilterVerb.ne,
  ];
}

class StringField extends PostFilterField {
  const StringField(super.name);

  @override
  List<PostFilterVerb> get verbs => const [
    PostFilterVerb.eq,
    PostFilterVerb.ne,
    PostFilterVerb.include,
    PostFilterVerb.match,
  ];
}

class ArrayField extends PostFilterField {
  const ArrayField(super.name);

  @override
  List<PostFilterVerb> get verbs => const [PostFilterVerb.include];
}

class MapField extends PostFilterField {
  const MapField(super.name);

  @override
  List<PostFilterVerb> get verbs => const [
    PostFilterVerb.eq,
    PostFilterVerb.ne,
  ];
}

const List<PostFilterField> postFilterHoleFieldNames = [
  MapField('hole'),
  NumberField('id'),
  NumberField('holeId'),
  NumberField('divisionId'),
  ArrayField('tags'),
  NumberField('view'),
  NumberField('reply'),
  NumberField('favoriteCount'),
  NumberField('subscriptionCount'),
  StringField('timeCreated'),
  StringField('created'),
  StringField('timeUpdated'),
  StringField('updated'),
  MapField('first'),
  StringField('content'),
  StringField('firstContent'),
  MapField('last'),
  StringField('lastContent'),
];

const List<PostFilterField> postFilterFloorFieldNames = [
  MapField('floor'),
  MapField('hole'),
  NumberField('id'),
  NumberField('floorId'),
  NumberField('holeId'),
  StringField('content'),
  StringField('anonyname'),
  StringField('name'),
  StringField('specialTag'),
  StringField('timeCreated'),
  StringField('created'),
  StringField('timeUpdated'),
  StringField('updated'),
  BooleanField('deleted'),
  BooleanField('modified'),
  BooleanField('isMe'),
  BooleanField('liked'),
  BooleanField('disliked'),
  NumberField('like'),
  NumberField('dislike'),
  ArrayField('mention'),
];

sealed class PostFilterExpr {
  const PostFilterExpr();

  String toJs();
}

enum PostFilterRelation {
  and('&&'),
  or('||');

  final String token;

  const PostFilterRelation(this.token);

  IconData icon(BuildContext context) {
    return switch (this) {
      PostFilterRelation.and =>
        PlatformX.isMaterial(context)
            ? Icons.call_merge
            : CupertinoIcons.arrow_merge,
      PostFilterRelation.or =>
        PlatformX.isMaterial(context)
            ? Icons.call_split
            : CupertinoIcons.arrow_branch,
    };
  }
}

class PostFilterGroup extends PostFilterExpr {
  final List<PostFilterSlot> slots = [];
  PostFilterRelation relation;
  bool negated;

  PostFilterGroup({required this.relation, this.negated = false});

  PostFilterGroup.and() : this(relation: PostFilterRelation.and);

  PostFilterGroup.or() : this(relation: PostFilterRelation.or);

  PostFilterGroup.nand()
    : this(relation: PostFilterRelation.and, negated: true);

  PostFilterGroup.nor() : this(relation: PostFilterRelation.or, negated: true);

  @override
  String toJs() {
    final joined = slots
        .map((slot) => '(${slot.expr.toJs()})')
        .join(' ${relation.token} ');
    return negated ? '!($joined)' : joined;
  }
}

class PostFilterCondition extends PostFilterExpr {
  final PostFilterField? subject;
  final PostFilterVerb verb;
  final PostFilterValue? object;

  const PostFilterCondition({
    this.subject,
    this.verb = PostFilterVerb.eq,
    this.object,
  });

  factory PostFilterCondition.fromField(
    PostFilterField field, [
    PostFilterVerb verb = PostFilterVerb.eq,
  ]) {
    return PostFilterCondition(
      subject: field,
      verb: verb,
      object: field.defaultObject(verb),
    );
  }

  PostFilterCondition copyWith({
    PostFilterField? subject,
    PostFilterVerb? verb,
    PostFilterValue? object,
  }) {
    return PostFilterCondition(
      subject: subject ?? this.subject,
      verb: verb ?? this.verb,
      object: object ?? this.object,
    );
  }

  @override
  String toJs() {
    return switch ((subject, verb.isOperator, object)) {
      (final s?, false, final o?) => '${s.name}.${verb.token}(${o.token})',
      (final s?, true, final o?) => '${s.name} ${verb.token} (${o.token})',
      (null, _, _) || (_, _, null) => 'false',
    };
  }
}

class PostFilterRawCondition extends PostFilterExpr {
  final String raw;

  const PostFilterRawCondition(this.raw);

  @override
  String toJs() => raw;
}

class PostFilterSlot {
  PostFilterExpr expr;
  PostFilterGroup group;

  PostFilterSlot({required this.expr, required this.group});
}

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

  void toggleGroupRelation(PostFilterGroup group) {
    group.relation = switch (group.relation) {
      PostFilterRelation.and => PostFilterRelation.or,
      PostFilterRelation.or => PostFilterRelation.and,
    };
    notifyListeners();
  }

  void toggleGroupNegated(PostFilterGroup group) {
    group.negated = !group.negated;
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
          for (final childSlot in group.slots)
            switch (childSlot.expr) {
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
              // TODO: Implement it.
              PostFilterRawCondition rawCond => Text(rawCond.raw),
            },
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
          _buildGroupNegationSelector(context, group),
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
          Expanded(child: _buildConditionSubjectSelector(context, cond, slot)),
          const SizedBox(width: 4),
          if (cond.subject is BooleanField)
            Text('is', style: _labelSmallStyle(context))
          else
            _buildConditionVerbSelector(context, cond, slot),
          const SizedBox(width: 4),
          Expanded(child: _buildConditionObjectSelector(context, cond, slot)),
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
                  PostFilterCondition.new,
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
                _buildAddExprListTile(
                  context,
                  group,
                  'NOT AND group',
                  PostFilterGroup.nand,
                ),
                _buildAddExprListTile(
                  context,
                  group,
                  'NOT OR group',
                  PostFilterGroup.nor,
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

  // ======== EXPRESSION SELECTORS ========

  Widget _buildGroupNegationSelector(
    BuildContext context,
    PostFilterGroup group,
  ) {
    return _buildTapChipButton(
      context,
      onTap: () => controller.toggleGroupNegated(group),
      label: group.negated ? 'Negated Group' : 'Group',
      icon: group.negated
          ? PlatformX.isMaterial(context)
                ? Icons.not_interested
                : CupertinoIcons.clear_circled
          : null,
    );
  }

  Widget _buildGroupRelationSelector(
    BuildContext context,
    PostFilterGroup group,
  ) {
    return _buildTapChipButton(
      context,
      onTap: () => controller.toggleGroupRelation(group),
      label: group.relation.name.toUpperCase(),
      icon: group.relation.icon(context),
    );
  }

  Widget _buildConditionSubjectSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterField>(
      context,
      items: [
        for (final field in fields)
          if (!field.shouldSkip)
            PopupMenuItem(
              value: field,
              child: _buildPopupAvatarItem(
                context,
                field.icon(context),
                field.name,
              ),
            ),
      ],
      initialValue: cond.subject,
      onSelected: (field) =>
          controller.replaceSlot(slot, PostFilterCondition.fromField(field)),
      label: cond.subject?.name ?? '',
      icon: cond.subject?.icon(context),
      autoOpen: cond.subject == null,
    );
  }

  Widget _buildConditionVerbSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterVerb>(
      context,
      items: [
        for (final verb in cond.subject?.verbs ?? const [])
          PopupMenuItem(value: verb, child: Text(verb.token)),
      ],
      initialValue: cond.verb,
      onSelected: (verb) => controller.replaceSlot(
        slot,
        cond.copyWith(
          verb: verb,
          object: cond.object ?? cond.subject?.defaultObject(verb),
        ),
      ),
      label: cond.verb.token,
    );
  }

  Widget _buildConditionObjectSelector(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) {
    return _buildPopupChipButton<PostFilterValue>(
      context,
      items: [
        if (cond.subject is BooleanField)
          for (final b in const ['false', 'true'])
            PopupMenuItem(value: PostFilterLiteralValue(b), child: Text(b))
        else ...[
          if (cond.subject?.defaultObject(cond.verb).token case final o?)
            PopupMenuItem(value: PostFilterLiteralValue(o), child: Text(o)),
          const PopupMenuItem(
            value: PostFilterRawValue(),
            child: Text('Custom input...'),
          ),
        ],
        const PopupMenuDivider(),
        for (final field in fields)
          if (field.runtimeType == cond.subject?.runtimeType)
            PopupMenuItem(
              value: PostFilterFieldValue(field),
              child: _buildPopupAvatarItem(
                context,
                field.icon(context),
                field.name,
              ),
            ),
      ],
      initialValue: cond.object,
      onSelected: (value) async {
        if (value is PostFilterRawValue
                ? await _showStringValueInputDialog(context, cond, slot)
                : value
            case final o?) {
          controller.replaceSlot(slot, cond.copyWith(object: o));
        }
      },
      label: cond.object?.token ?? '',
      icon: switch (cond.object) {
        PostFilterFieldValue(:final field) => field.icon(context),
        _ => null,
      },
    );
  }

  // ======== WIDGETS ========

  Widget _buildTapChipButton(
    BuildContext context, {
    required VoidCallback onTap,
    required String label,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: _buildChipButton(context, label, icon: icon),
    );
  }

  Widget _buildPopupChipButton<T>(
    BuildContext context, {
    required List<PopupMenuEntry<T>> items,
    required T? initialValue,
    required ValueChanged<T> onSelected,
    EdgeInsets padding = EdgeInsets.zero,
    required String label,
    IconData? icon,
    bool autoOpen = false,
  }) {
    final child = _buildChipButton(context, label, icon: icon);
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

  Widget _buildChipButton(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: _chipDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(icon, size: 12, color: _chipContentColor(context)),
            ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _chipContentColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<PostFilterLiteralValue?> _showStringValueInputDialog(
    BuildContext context,
    PostFilterCondition cond,
    PostFilterSlot slot,
  ) async {
    final prompt = switch (cond.verb) {
      PostFilterVerb.eq => 'Exact value',
      PostFilterVerb.ne => 'Exclude value',
      PostFilterVerb.include => 'Substring',
      PostFilterVerb.match => 'Regex pattern',
      _ => 'Unknown verb',
    };
    final example = switch (cond.verb) {
      PostFilterVerb.eq || PostFilterVerb.ne => '"content"',
      PostFilterVerb.include => '"keyword"',
      PostFilterVerb.match => '/regex/i',
      _ => '',
    };
    final textController = TextEditingController(
      text: switch (cond.object) {
        PostFilterLiteralValue(:final literal) => literal,
        _ => null,
      },
    );
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
    return switch (result) {
      final r? when r.isNotEmpty => PostFilterLiteralValue(r),
      _ => null,
    };
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

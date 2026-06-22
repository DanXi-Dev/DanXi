import 'dart:convert';

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

class PostFilterInputValue extends PostFilterValue {
  final PostFilterValueType? type;

  const PostFilterInputValue({this.type});

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

enum PostFilterValueType {
  boolean, // The JS Boolean, not the Dart bool.
  number,
  string,
  array,
  regExp, // The JS RegExp.
  object // The JS Object. Conceptually Array and RegExp are Object too.
  ;

  PostFilterLiteralValue get defaultValue {
    final literal = switch (this) {
      PostFilterValueType.boolean => 'true',
      PostFilterValueType.number => '0',
      PostFilterValueType.string => '""',
      PostFilterValueType.array => '[]',
      PostFilterValueType.regExp => '/^/',
      PostFilterValueType.object => '{}',
    };
    return PostFilterLiteralValue(literal);
  }
}

class PostFilterField {
  final PostFilterValueType type;
  final String name;

  const PostFilterField(this.type, this.name);

  const PostFilterField.boolean(this.name) : type = PostFilterValueType.boolean;

  const PostFilterField.number(this.name) : type = PostFilterValueType.number;

  const PostFilterField.string(this.name) : type = PostFilterValueType.string;

  const PostFilterField.array(this.name) : type = PostFilterValueType.array;

  const PostFilterField.object(this.name) : type = PostFilterValueType.object;

  bool get shouldSkip => switch (type) {
    PostFilterValueType.array || PostFilterValueType.object => true,
    _ => false,
  };

  List<PostFilterVerb> get verbs => switch (type) {
    PostFilterValueType.boolean => const [PostFilterVerb.eq],
    PostFilterValueType.number => const [
      PostFilterVerb.lt,
      PostFilterVerb.gt,
      PostFilterVerb.le,
      PostFilterVerb.ge,
      PostFilterVerb.eq,
      PostFilterVerb.ne,
    ],
    PostFilterValueType.string => const [
      PostFilterVerb.eq,
      PostFilterVerb.ne,
      PostFilterVerb.include,
      PostFilterVerb.match,
    ],
    PostFilterValueType.array => const [
      PostFilterVerb.eq,
      PostFilterVerb.include,
    ],
    PostFilterValueType.regExp => const [
      PostFilterVerb.eq,
      PostFilterVerb.match,
    ],
    PostFilterValueType.object => const [PostFilterVerb.eq],
  };

  PostFilterValueType objectType(PostFilterVerb verb) => switch (type) {
    PostFilterValueType.boolean => PostFilterValueType.boolean,
    PostFilterValueType.number => PostFilterValueType.number,
    PostFilterValueType.string => switch (verb) {
      PostFilterVerb.match => PostFilterValueType.regExp,
      _ => PostFilterValueType.string,
    },
    PostFilterValueType.regExp => PostFilterValueType.string,
    PostFilterValueType.array => PostFilterValueType.array,
    PostFilterValueType.object => PostFilterValueType.object,
  };

  IconData icon(BuildContext context) => switch (type) {
    PostFilterValueType.boolean =>
      PlatformX.isMaterial(context)
          ? Icons.toggle_on
          : CupertinoIcons.plus_slash_minus,
    PostFilterValueType.number =>
      PlatformX.isMaterial(context) ? Icons.numbers : CupertinoIcons.number,
    PostFilterValueType.string =>
      PlatformX.isMaterial(context) ? Icons.abc : CupertinoIcons.textformat_abc,
    PostFilterValueType.array =>
      PlatformX.isMaterial(context)
          ? Icons.data_array
          : CupertinoIcons.list_bullet,
    PostFilterValueType.regExp =>
      PlatformX.isMaterial(context)
          ? Icons.manage_search
          : CupertinoIcons.slash_circle,
    PostFilterValueType.object =>
      PlatformX.isMaterial(context)
          ? Icons.data_object
          : CupertinoIcons.collections,
  };
}

const List<PostFilterField> postFilterHoleFieldNames = [
  PostFilterField.object('hole'),
  PostFilterField.number('id'),
  PostFilterField.number('holeId'),
  PostFilterField.number('divisionId'),
  PostFilterField.array('tags'),
  PostFilterField.number('view'),
  PostFilterField.number('reply'),
  PostFilterField.number('favoriteCount'),
  PostFilterField.number('subscriptionCount'),
  PostFilterField.string('timeCreated'),
  PostFilterField.string('created'),
  PostFilterField.string('timeUpdated'),
  PostFilterField.string('updated'),
  PostFilterField.object('first'),
  PostFilterField.string('content'),
  PostFilterField.string('firstContent'),
  PostFilterField.object('last'),
  PostFilterField.string('lastContent'),
];

const List<PostFilterField> postFilterFloorFieldNames = [
  PostFilterField.object('floor'),
  PostFilterField.object('hole'),
  PostFilterField.number('id'),
  PostFilterField.number('floorId'),
  PostFilterField.number('holeId'),
  PostFilterField.string('content'),
  PostFilterField.string('anonyname'),
  PostFilterField.string('name'),
  PostFilterField.string('specialTag'),
  PostFilterField.string('timeCreated'),
  PostFilterField.string('created'),
  PostFilterField.string('timeUpdated'),
  PostFilterField.string('updated'),
  PostFilterField.boolean('deleted'),
  PostFilterField.boolean('modified'),
  PostFilterField.boolean('isMe'),
  PostFilterField.boolean('liked'),
  PostFilterField.boolean('disliked'),
  PostFilterField.number('like'),
  PostFilterField.number('dislike'),
  PostFilterField.array('mention'),
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
      object: field.objectType(verb).defaultValue,
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
  final String? raw;

  const PostFilterRawCondition({this.raw});

  @override
  String toJs() => raw ?? 'false';
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
              PostFilterRawCondition rawCond => _buildRawConditionRow(
                context,
                rawCond,
                childSlot,
              ),
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
          if (cond.subject?.type == PostFilterValueType.boolean)
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

  Widget _buildRawConditionRow(
    BuildContext context,
    PostFilterRawCondition rawCond,
    PostFilterSlot slot,
  ) {
    final onAutoOpen = () async {
      if (await _showRawConditionInputDialog(context, rawCond) case final o
          when o.raw != null) {
        controller.replaceSlot(slot, o);
      }
    };
    final child = Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onAutoOpen,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: _chipDecoration(context),
              child: Text(
                rawCond.raw ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _chipContentColor(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _buildCloseButton(context, slot),
      ],
    );
    return rawCond.raw == null
        ? _AutoOpenWrapper(onAutoOpen: onAutoOpen, child: child)
        : child;
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
                  'Raw expression',
                  PostFilterRawCondition.new,
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
          object: cond.object ?? cond.subject?.objectType(verb).defaultValue,
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
    final objectType = cond.subject?.objectType(cond.verb);
    final objectFields = [
      for (final field in fields)
        if (field.type == objectType) field,
    ];
    return _buildPopupChipButton<PostFilterValue>(
      context,
      items: [
        if (objectType?.defaultValue.token case final o?)
          PopupMenuItem(value: PostFilterLiteralValue(o), child: Text(o)),
        ...switch (objectType) {
          PostFilterValueType.boolean => [
            for (final b in const ['false', 'true'])
              PopupMenuItem(value: PostFilterLiteralValue(b), child: Text(b)),
          ],
          PostFilterValueType.number ||
          PostFilterValueType.string ||
          PostFilterValueType.regExp => [
            PopupMenuItem(
              value: PostFilterInputValue(type: objectType),
              child: const Text('Input content'),
            ),
          ],
          _ => const [],
        },
        if (objectFields.isNotEmpty) const PopupMenuDivider(),
        for (final field in objectFields)
          PopupMenuItem(
            value: PostFilterFieldValue(field),
            child: _buildPopupAvatarItem(
              context,
              field.icon(context),
              field.name,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: PostFilterInputValue(),
          child: const Text('Custom expression'),
        ),
      ],
      initialValue: cond.object,
      onSelected: (value) async {
        if (switch (value) {
              PostFilterInputValue(type: final inputType) =>
                await switch (inputType) {
                  PostFilterValueType.number => _showNumberInputDialog(
                    context,
                    cond,
                  ),
                  PostFilterValueType.string => _showStringInputDialog(
                    context,
                    cond,
                  ),
                  PostFilterValueType.regExp => _showRegExpInputDialog(
                    context,
                    cond,
                  ),
                  _ => _showRawValueInputDialog(context, cond),
                },
              _ => value,
            }
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

  Future<PostFilterLiteralValue?> _showNumberInputDialog(
    BuildContext context,
    PostFilterCondition cond,
  ) async {
    final result = await _showTextInputDialog(
      context,
      prompt: switch (cond.verb) {
        PostFilterVerb.lt => 'Less than',
        PostFilterVerb.gt => 'Greater than',
        PostFilterVerb.le => 'At most',
        PostFilterVerb.ge => 'At least',
        PostFilterVerb.eq => 'Exact value',
        PostFilterVerb.ne => 'Exclude value',
        _ => null,
      },
      initialValue: switch (cond.object) {
        PostFilterLiteralValue(:final literal) => literal,
        _ => null,
      },
      hintText: 'e.g. 42',
      keyboardType: TextInputType.number,
      contentBuilder: (textController, textField) => Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (num.tryParse(textController.text) case final current?) {
                textController.text = (current - 1).toString();
              }
            },
          ),
          Expanded(child: textField),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (num.tryParse(textController.text) case final current?) {
                textController.text = (current + 1).toString();
              }
            },
          ),
        ],
      ),
    );
    return switch (result) {
      final r? when r.isNotEmpty && r.isNumber() => PostFilterLiteralValue(r),
      _ => null,
    };
  }

  Future<PostFilterLiteralValue?> _showStringInputDialog(
    BuildContext context,
    PostFilterCondition cond,
  ) async {
    final result = await _showTextInputDialog(
      context,
      prompt: switch (cond.verb) {
        PostFilterVerb.eq || PostFilterVerb.ne => 'Exact value',
        PostFilterVerb.include => 'Substring',
        _ => null,
      },
      initialValue: switch (cond.object) {
        PostFilterLiteralValue(:final literal) => switch ((() {
          try {
            return jsonDecode(literal);
          } catch (_) {
            return null;
          }
        })()) {
          final String content? => content,
          _ => null,
        },
        _ => null,
      },
      hintText: switch (cond.verb) {
        PostFilterVerb.eq || PostFilterVerb.ne => 'content',
        PostFilterVerb.include => 'keyword',
        _ => null,
      },
    );
    return switch (result) {
      final r? => PostFilterLiteralValue(jsonEncode(r)),
      _ => null,
    };
  }

  Future<PostFilterLiteralValue?> _showRegExpInputDialog(
    BuildContext context,
    PostFilterCondition cond,
  ) async {
    final result = await _showTextInputDialog(
      context,
      prompt: 'Regex pattern',
      initialValue: switch (cond.object) {
        PostFilterLiteralValue(:final literal) => literal,
        _ => null,
      },
      hintText: '/pattern/i',
    );
    return switch (result) {
      final r? when r.isNotEmpty => PostFilterLiteralValue(r),
      _ => null,
    };
  }

  Future<PostFilterLiteralValue?> _showRawValueInputDialog(
    BuildContext context,
    PostFilterCondition cond,
  ) async {
    final result = await _showTextInputDialog(
      context,
      prompt: 'Raw JS value',
      initialValue: cond.object?.token,
    );
    return switch (result) {
      final r? when r.isNotEmpty => PostFilterLiteralValue(r),
      _ => null,
    };
  }

  Future<PostFilterRawCondition> _showRawConditionInputDialog(
    BuildContext context,
    PostFilterRawCondition rawCond,
  ) async {
    final result = await _showTextInputDialog(
      context,
      prompt: 'Raw JS condition',
      initialValue: rawCond.raw,
    );
    return PostFilterRawCondition(
      raw: switch (result) {
        final r? when r.isNotEmpty => r,
        _ => null,
      },
    );
  }

  Future<String?> _showTextInputDialog(
    BuildContext context, {
    String? prompt,
    String? initialValue,
    String? hintText,
    TextInputType? keyboardType,
    Widget Function(TextEditingController, Widget)? contentBuilder,
  }) async {
    final textController = TextEditingController(text: initialValue);
    final defaultTextField = TextField(
      controller: textController,
      decoration: InputDecoration(hintText: hintText),
      keyboardType: keyboardType,
      autofocus: true,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prompt != null) ...[
              Text(prompt, style: _labelSmallStyle(context)),
              const SizedBox(height: 8),
            ],
            contentBuilder?.call(textController, defaultTextField) ??
                defaultTextField,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
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

  @override
  Widget build(BuildContext context) {
    return _AutoOpenWrapper(
      onAutoOpen: () => _key.currentState?.showButtonMenu(),
      child: PopupMenuButton<T>(
        key: _key,
        itemBuilder: (_) => widget.items,
        initialValue: widget.initialValue,
        onSelected: widget.onSelected,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

class _AutoOpenWrapper extends StatefulWidget {
  final Function() onAutoOpen;
  final Widget child;

  const _AutoOpenWrapper({required this.onAutoOpen, required this.child});

  @override
  State<_AutoOpenWrapper> createState() => _AutoOpenWrapperState();
}

class _AutoOpenWrapperState extends State<_AutoOpenWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAutoOpen();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

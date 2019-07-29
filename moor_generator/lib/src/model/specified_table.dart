import 'package:moor_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:recase/recase.dart';

/// A parsed table, declared in code by extending `Table` and referencing that
/// table in `@UseMoor` or `@UseDao`.
class SpecifiedTable {
  /// The [ClassElement] for the class that declares this table or null if
  /// the table was inferred from a `CREATE TABLE` statement.
  final ClassElement fromClass;

  /// If [fromClass] is null, another source to use when determining the name
  /// of this table in generated Dart code.
  final String _overriddenName;

  String get _baseName => _overriddenName ?? fromClass.name;

  /// The columns declared in this table.
  final List<SpecifiedColumn> columns;

  /// The name of this table when stored in the database
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  String get tableFieldName => ReCase(_baseName).camelCase;
  String get tableInfoName => tableInfoNameForTableClass(_baseName);
  String get updateCompanionName => _updateCompanionName(_baseName);

  /// The set of primary keys, if they have been explicitly defined by
  /// overriding `primaryKey` in the table class. `null` if the primary key has
  /// not been defined that way.
  final Set<SpecifiedColumn> primaryKey;

  const SpecifiedTable(
      {this.fromClass,
      this.columns,
      this.sqlName,
      this.dartTypeName,
      this.primaryKey,
      String overriddenName})
      : _overriddenName = overriddenName;

  /// Finds all type converters used in this tables.
  Iterable<UsedTypeConverter> get converters =>
      columns.map((c) => c.typeConverter).where((t) => t != null);
}

String tableInfoNameForTableClass(String className) => '\$${className}Table';

String _updateCompanionName(String className) => '${className}Companion';

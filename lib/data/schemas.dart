import '../models/sheet_type.dart';
import 'schema_dark_ages.dart';
import 'schema_dark_ages_first.dart';
import 'schema_v20.dart';
import 'schema_v5.dart';
import 'sheet_schema.dart';

export 'sheet_schema.dart';

/// Lo schema corrispondente a una tipologia di scheda.
SheetSchema schemaFor(SheetType type) => switch (type) {
  SheetType.v5 => v5Schema,
  SheetType.v20 => v20Schema,
  SheetType.darkAges20 => darkAgesSchema,
  SheetType.darkAges1 => darkAges1Schema,
};

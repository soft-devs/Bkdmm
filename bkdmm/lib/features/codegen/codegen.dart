// Code Generation Feature
//
// This feature provides DDL generation for multiple database types:
// - MySQL
// - PostgreSQL
// - Oracle
// - SQL Server
// - SQLite
//
// Template variables available:
// - {{tableName}} / {{entity.title}} - Table name
// - {{tableComment}} / {{entity.chnname}} - Chinese name
// - {{#fields}}...{{/fields}} - Iterate fields
// - {{field.name}} - Field name
// - {{field.typeDB}} - Database-specific type
// - {{field.pk}} - Is primary key (boolean)
// - {{field.notNull}} - Is not null (boolean)
// - {{field.autoIncrement}} - Is auto increment (boolean)
// - {{field.defaultValue}} - Default value
// - {{field.remark}} - Field comment

export 'services/codegen_service.dart';
export 'services/template_service.dart';
export 'providers/codegen_provider.dart';
export 'views/codegen_view.dart';
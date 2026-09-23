import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;

  CategoryRepositoryImpl(this._db);

  Category _mapToDomain(CategoryData data) {
    return Category(
      id: data.id,
      parentId: data.parentId,
      name: data.name,
      icon: data.icon,
      color: data.color,
    );
  }

  CategoriesCompanion _mapToDb(Category category) {
    return CategoriesCompanion.insert(
      id: category.id,
      parentId: Value(category.parentId),
      name: category.name,
      icon: Value(category.icon),
      color: Value(category.color),
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    final result = await _db.select(_db.categories).get();
    return result.map(_mapToDomain).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final result = await (_db.select(
      _db.categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return result != null ? _mapToDomain(result) : null;
  }

  @override
  Future<void> addCategory(Category category) async {
    await _db.into(_db.categories).insert(_mapToDb(category));
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _db.update(_db.categories).replace(_mapToDb(category));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Stream<List<Category>> watchCategories() {
    return _db
        .select(_db.categories)
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }
}

class DefaultCategoryProvider : CategoryProvider
{
    func getAll(but categoriesToFilter: Category...) -> [Category]
    {
        return Category.all.filter { !categoriesToFilter.contains($0) }
    }
}

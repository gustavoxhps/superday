class OnboardingCategoryProvider : CategoryProvider
{
    private let categoryToSelect : Category
    
    init(withFirstCategory categoryToSelect: Category)
    {
        self.categoryToSelect = categoryToSelect
    }
    
    func getAll(but categoriesToFilter: Category...) -> [Category]
    {
        return [ categoryToSelect ] + Category.all.filter { !categoriesToFilter.contains($0) && $0 != categoryToSelect }
    }
}

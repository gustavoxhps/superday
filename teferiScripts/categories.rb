require 'json'

currentPath = File.dirname(__FILE__)
sourcePath = currentPath + "/categories.json"
destinationPath = File.expand_path("../teferi/Generated/Category.swift", currentPath)

sourceFile = File.read(sourcePath)
categories = JSON.parse(sourceFile).map { | c | c[0] }

cases = categories.map { |c| "    case #{c}" }.join("\n")

attributes = categories.map{ |c| 
"        case .#{c}:
            return (description: L10n.#{c}, color: UIColor(named: .#{c}), icon: .ic#{c.capitalize}Icon)" 
        }.join("\n")

allCategories = categories.map{ |c| ".#{c}" }.join(", ")

fileContents =
"import UIKit

enum Category : String
{
#{cases}

    //MARK: Properties
        
    private typealias CategoryData = (description: String, color: UIColor, icon: Asset)
        
    private var attributes : CategoryData
    {
        switch self
        {
#{attributes}
        }
    }
    
    /// Get all categories
    static let all : [Category] = [ #{allCategories} ]
    
    /// Get the Color associated with the category.
    var color : UIColor
    {
        return self.attributes.color
    }
    
    /// Get the Asset for the category.
    var icon : Asset
    {
        return self.attributes.icon
    }
    
    /// Get the Localised name for the category.
    var description : String
    {
        return self.attributes.description
    }
}"

File.write(destinationPath, fileContents)
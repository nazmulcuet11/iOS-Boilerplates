import UIKit

/// Provide mixins for easy loading of UIViewController from UIStoryboard
protocol StoryboardBased {
    /// Name of the storyboard from which view controller will be instantiated
    /// Default implementation assumes that Storyboard name is same as the target UIViewController name 
    /// Must override this property if storyboard name is different from view controller's name
    static var storyboardName: String { get }
    
    /// Storyboard identifier for the view controller
    /// Default implementation assumes that Storyboard name is same as the target UIViewController name 
    /// Must override this property if storyboard identifier is different from view controller's name
    static var storyboardIdentifier: String { get }

    /// This method instantiate a UIViewController from UIStoryboard
    /// Don't implement this method, if you specify storyboardName and 
    // storyboardIdentifier correctly, this method shoud work as is
    /// - Returns: UIViewController
    static func instantiate() -> Self
}

extension StoryboardBased where Self: UIViewController {
    static var storyboardName: String {
        return "\(Self.self)"
    }

    static var storyboardIdentifier: String {
        return "\(Self.self)"
    }

    static func instantiate() -> Self  {
        let storyboard = UIStoryboard(name: storyboardName , bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as? Self else {
            fatalError("Can't load view controller \(Self.self) from storyboard named \(storyboardName)")
        }
        return viewController
    }
}
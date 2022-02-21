//
//  UICollectionView+Convenience.swift
//  CustomCollectionViewLayout
//
//  Created by Nazmul Islam on 3/4/21.
//

import UIKit

extension UICollectionView {
    func registerCell<T: UICollectionViewCell>(_ cellClass: T.Type) {
        register(cellClass, forCellWithReuseIdentifier: T.reuseID)
    }

    func registerNibCell<T: UICollectionViewCell>(_ cellClass: T.Type, nibName: String = T.reuseID) {
        register(UINib(nibName: nibName, bundle: nil), forCellWithReuseIdentifier: T.reuseID)
    }

    func registerReusableSupplementaryView<T: UICollectionReusableView>(_ viewClass: T.Type, ofKind kind: String) {
        register(viewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseID)
    }

    func registerNibReusableSupplementaryView<T: UICollectionReusableView>(_ viewClass: T.Type, ofKind kind: String, nibName: String = T.reuseID) {
        register(UINib(nibName: nibName, bundle: nil), forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseID)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseID, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseID) for cell at \(indexPath)")
        }
        return cell
    }

    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(_ viewClass: T.Type, ofKind kind: String, for indexPath: IndexPath) -> T {

        guard let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseID, for: indexPath) as? T else {
            fatalError("Could not dequeue UICollectionReusableView with identifier: \(T.reuseID)")
        }
        
        return view
    }
}

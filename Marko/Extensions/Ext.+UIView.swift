//
//  Ext.+UIView.swift
//  Marko
//
//  Created by Ivan on 03.04.2025.
//

import UIKit

extension UIView {
    func addSubviews(views: [UIView]) {
        views.forEach { child in
            addSubview(child)
        }
    }
}

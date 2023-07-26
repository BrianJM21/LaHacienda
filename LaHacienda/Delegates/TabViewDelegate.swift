//
//  TabViewDelegate.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation

protocol TabViewDelegate: NSObject {
    func completeOrder()
    func logOut(to newRootViewController: RouterService)
}

extension TabViewDelegate {
    func completeOrder() {}
    func logOut(to newRootViewController: RouterService) {}
}

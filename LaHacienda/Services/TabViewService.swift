//
//  TabViewService.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit

protocol TabViewService {
    
    var viewController: UIViewController { get set }
    
    func setup()
    func fetchData()
    func reArrangeSubViews()
}

extension TabViewService {
    func reArrangeSubViews() {}
}

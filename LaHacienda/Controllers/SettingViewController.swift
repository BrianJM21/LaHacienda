//
//  SettingViewController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class SettingViewController: UIViewController {
    
    convenience init(delegate: TabViewDelegate) {
        self.init()
        self.delegate = delegate
        loadViewIfNeeded()
    }
    
    deinit {
        print("SE DESTRUYÓ SETTING VIEW CONTROLLER")
    }
    
    var tabView: TabViewService?
    weak var delegate: TabViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabView = SettingView(viewController: self, delegate: self)
        tabView?.setup()
        tabView?.fetchData()
    }
}

extension SettingViewController: TabViewDelegate {
    
    func logOut(to newRootViewController: RouterService) {
        tabView = nil
        delegate?.logOut(to: newRootViewController)
    }
}

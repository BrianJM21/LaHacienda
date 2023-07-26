//
//  HomeViewController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class HomeViewController: UIViewController {
    
    deinit {
        print("SE DESTRUYÓ HOME VIEW CONTROLLER")
    }
    
    var tabView: TabViewService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabView = HomeView(viewController: self)
        tabView?.setup()
        tabView?.fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabView?.fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        tabView?.reArrangeSubViews()
    }
}

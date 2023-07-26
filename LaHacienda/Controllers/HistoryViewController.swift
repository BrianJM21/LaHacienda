//
//  HistoryViewController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class HistoryViewController: UIViewController {

    convenience init(_ loadView: Bool) {
        self.init()
        loadViewIfNeeded()
    }
    
    deinit {
        print("SE DESTRUYÓ HISTORY VIEW CONTROLLER")
    }
    
    var tabView: TabViewService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabView = HistoryView(viewController: self)
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

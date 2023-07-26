//
//  OrderViewController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class OrderViewController: UIViewController, TabViewDelegate {
    
    convenience init(_ loadView: Bool) {
        self.init()
        loadViewIfNeeded()
    }
    
    deinit {
        print("SE DESTRUYÓ ORDER VIEW CONTROLLER")
    }
    
    var tabView: TabViewService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initOrder()
    }
    
    func completeOrder() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        tabView = nil
        initOrder()
    }
    
    func initOrder() {
        tabView = OrderView(viewController: self, delegate: self)
        tabView?.setup()
        tabView?.fetchData()
    }
    
}

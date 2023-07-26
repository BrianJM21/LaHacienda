//
//  LoginViewController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class LoginViewController: UIViewController, RouterService {
    
    convenience init(router: RouterDelegate) {
        self.init()
        self.router = router
    }
    
    deinit {
        print("SE DESTRUYÓ LOGIN VIEW CONTROLLER")
    }
    
    var loginView: LoginViewService?
    var router: RouterDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginView = LoginView(viewController: self, delegate: self)
        loginView?.setup()
    }
    
}

extension LoginViewController: LoginViewDelegate {
    
    func login(to newRootViewController: RouterService) {
        loginView = nil
        router?.changeRootViewController(to: newRootViewController)
    }
    
    func changeView(to viewToCall: LoginViewService, fromPosition pixels: Double, inSeconds time: Double) {
        loginView = nil
        loginView = viewToCall
        loginView?.call(fromPosition: pixels, inSeconds: time)
    }
    
}

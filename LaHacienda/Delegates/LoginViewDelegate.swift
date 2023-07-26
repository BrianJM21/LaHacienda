//
//  LoginViewDelegate.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation

protocol LoginViewDelegate {
    
    func changeView(to viewToCall: LoginViewService, fromPosition pixels: Double, inSeconds time: Double)
    func login(to newRootViewController: RouterService)
}

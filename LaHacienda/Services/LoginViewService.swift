//
//  LoginViewService.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit

protocol LoginViewService {
    
    var viewController: UIViewController { get set }
    
    func setup()
    func call(fromPosition pixels: Double, inSeconds time: Double)
    func dismiss(toPosition pixels: Double, inSeconds time: Double)
    func dismissWithTransition(toPosition pixels: Double, inSeconds time: Double)
    func successfulLogin(to newRootViewController: RouterService)
}

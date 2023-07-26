//
//  LoginView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit

class LoginView: LoginViewService {
    
    init(viewController: UIViewController, delegate: LoginViewDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    deinit {
        print("SE DESTRUYÓ LOGIN VIEW")
    }
    
    unowned var viewController: UIViewController
    private var delegate: LoginViewDelegate
    private var vcToChange: LoginViewService?
    private let scrollable = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.delaysContentTouches = false
        return scroll
    }()
    private let container = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    private let title = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 30)
        label.text = "La Hacienda H2O"
        label.textAlignment = .center
        return label
    }()
    private let subTitle = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.text = "Tu App para pedir agua a domicilio."
        label.textAlignment = .center
        return label
    }()
    private let logoImage = {
        let image = UIImageView(image: UIImage(named: "Logo"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.heightAnchor.constraint(equalToConstant: 300).isActive = true
        image.widthAnchor.constraint(equalToConstant: 300).isActive = true
        return image
    }()
    private lazy var signInButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Iniciar Sesión", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signInButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var signUpButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Registrarse", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signUpButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var mainUIStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [title, subTitle, logoImage, signInButton, signUpButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        return stack
    }()
    private lazy var mainUIStackCenterXAnchor = mainUIStack.centerXAnchor.constraint(equalTo: container.centerXAnchor)
    
    func setup() {
        viewController.view.backgroundColor = .systemBackground
        viewController.view.addSubview(scrollable)
        scrollable.addSubview(container)
        container.addSubview(mainUIStack)
        NSLayoutConstraint.activate([
            scrollable.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
            scrollable.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor),
            scrollable.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor),
            scrollable.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            scrollable.frameLayoutGuide.heightAnchor.constraint(equalToConstant: UIScreen.main.fixedCoordinateSpace.bounds.size.height),
            container.topAnchor.constraint(equalTo: scrollable.contentLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scrollable.contentLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollable.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(equalTo: scrollable.frameLayoutGuide.heightAnchor),
            mainUIStackCenterXAnchor,
            mainUIStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)])
    }
    
    @objc private func signInButtonAction() {
        vcToChange = LoginWithEmailView(viewController: viewController, delegate: delegate)
        dismissWithTransition(toPosition: -700, inSeconds: 0.5)
    }
    
    @objc private func signUpButtonAction() {
        vcToChange = LoginSignUpView(viewController: viewController, delegate: delegate)
        dismissWithTransition(toPosition: -700, inSeconds: 0.5)
    }
    
    func dismissWithTransition(toPosition pixels: Double, inSeconds time: Double) {
        UIView.animate(withDuration: time) { [weak self] in
            self?.mainUIStackCenterXAnchor.constant = pixels
            self?.viewController.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let vcToChange = self?.vcToChange else { return }
            self?.delegate.changeView(to: vcToChange, fromPosition: (pixels * -1), inSeconds: time)
        }
    }
    
    func call(fromPosition pixels: Double, inSeconds time: Double) {
        let dwi1 = DispatchWorkItem { [weak self] in
            self?.mainUIStackCenterXAnchor.constant = pixels
            self?.setup()
        }
        let dwi2 = DispatchWorkItem {
            UIView.animate(withDuration: time) { [weak self] in
                self?.mainUIStackCenterXAnchor.constant = 0
                self?.viewController.view.layoutIfNeeded()
            }
        }
        dwi1.notify(queue: DispatchQueue.main, execute: dwi2)
        dwi1.perform()
    }
    
    func successfulLogin(to newRootViewController: RouterService) { }
    func dismiss(toPosition pixels: Double, inSeconds time: Double) { }
    
}

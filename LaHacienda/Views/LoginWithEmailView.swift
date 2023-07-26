//
//  LoginWithEmailView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit

class LoginWithEmailView: LoginViewService {
    
    init(viewController: UIViewController, delegate: LoginViewDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    deinit {
        print("SE DESTRUYO LOGIN WITH EMAIL VIEW")
    }
    
    unowned var viewController: UIViewController
    private var delegate: LoginViewDelegate
    private var loginAPI: LoginService?
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
        label.text = "Inicio de Sesión"
        label.textAlignment = .center
        return label
    }()
    private let subTitle = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.text = "Elige la opción deseada para acceder a tu cuenta."
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    private let email = {
        let text = UITextField()
        text.placeholder = "ejemplo@correo.com"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.keyboardType = .emailAddress
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return text
    }()
    private let password = {
        let text = UITextField()
        text.placeholder = "Contraseña_21"
        text.font = .systemFont(ofSize: 17)
        text.isSecureTextEntry = true
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return text
    }()
    private lazy var signInButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Acceder", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signInButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var facebookSignInButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("    Iniciar Sesión con Facebook", for: .normal)
        button.setImage(UIImage(named: "FacebookIconButton")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(facebookSignInButtonAction), for: .touchUpInside)
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
        let stack = UIStackView(arrangedSubviews: [title, subTitle, email, password, signInButton, facebookSignInButton, signUpButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        return stack
    }()
    private lazy var mainUIStackCenterXAnchor = mainUIStack.centerXAnchor.constraint(equalTo: container.centerXAnchor)
    private let busy = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.backgroundColor = UIColor(white: 1, alpha: 0.5)
        activityIndicator.layer.cornerRadius = 5
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    private let signUpUIResult = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.heightAnchor.constraint(equalToConstant: 150).isActive = true
        image.widthAnchor.constraint(equalToConstant: 150).isActive = true
        image.isHidden = true
        return image
    }()
    
    func setup() {
        viewController.view.backgroundColor = .systemBackground
        viewController.view.addSubview(scrollable)
        scrollable.addSubview(container)
        container.addSubview(mainUIStack)
        container.addSubview(busy)
        container.addSubview(signUpUIResult)
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
            mainUIStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            busy.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            busy.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            signUpUIResult.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            signUpUIResult.centerYAnchor.constraint(equalTo: container.centerYAnchor)])
       viewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
    }
    
    @objc private func hideKeyboard() {
        viewController.view.endEditing(true)
    }
    
    @objc private func signInButtonAction() {
        loginAPI = EmailAuthAPI()
        DispatchQueue.main.async { [weak self] in
            self?.busy.startAnimating()
            self?.signUpButton.isEnabled = false
            self?.facebookSignInButton.isEnabled = false
            self?.signInButton.isEnabled = false
        }
        guard let email = email.text, let password = password.text else { return }
        loginAPI?.logIn(email: email, password: password) { [weak self] result in
            self?.busy.stopAnimating()
            switch result {
            case .success(_) :
                self?.signUpUIResult.image = UIImage(systemName: "checkmark.circle")
                self?.signUpUIResult.tintColor = .green
                self?.signUpUIResult.isHidden = false
                self?.dismiss(toPosition: -700, inSeconds: 0.5)
            case .failure(_) :
                self?.signUpUIResult.image = UIImage(systemName: "x.circle")
                self?.signUpUIResult.tintColor = .red
                self?.signUpUIResult.isHidden = false
                self?.signUpButton.isEnabled = true
                self?.facebookSignInButton.isEnabled = true
                self?.signInButton.isEnabled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.signUpUIResult.isHidden = true
                }
            }
        }
    }
    
    @objc private func facebookSignInButtonAction() {
        print("Facebook Sign In")
    }
    
    @objc private func signUpButtonAction() {
        dismissWithTransition(toPosition: 700, inSeconds: 0.5)
    }
    
    func dismissWithTransition(toPosition pixels: Double, inSeconds time: Double) {
        UIView.animate(withDuration: time) { [weak self] in
            self?.mainUIStackCenterXAnchor.constant = pixels
            self?.viewController.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let vc = self?.viewController, let delegate = self?.delegate else { return }
            self?.delegate.changeView(to: LoginSignUpView(viewController: vc, delegate: delegate), fromPosition: (pixels * -1), inSeconds: time)
        }
    }
    
    func dismiss(toPosition pixels: Double, inSeconds time: Double) {
        UIView.animate(withDuration: time) { [weak self] in
            self?.mainUIStackCenterXAnchor.constant = pixels
            self?.viewController.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.successfulLogin(to: TabBarController())
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
    
    func successfulLogin(to newRootViewController: RouterService) {
        delegate.login(to: newRootViewController)
    }
  
}

//
//  LoginSignUpView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit
import Combine

class LoginSignUpView: NSObject, LoginViewService, UITableViewDataSource, UITableViewDelegate {
    
    init(viewController: UIViewController, delegate: LoginViewDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    deinit {
        print("SE DESTRUYO LOGIN SIGN UP VIEW")
        fetchedPlacesSubscriber?.cancel()
    }
    
    unowned var viewController: UIViewController
    private var delegate: LoginViewDelegate
    private var loginAPI: LoginService?
    private let viewModel = LoginSignUpViewModel()
    private let locationManager = LocationManager()
    private var fetchedPlacesSubscriber: AnyCancellable?
    private var confirmLocationSubscriber: AnyCancellable?
    private let scrollable = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
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
        label.text = "Regístrate"
        label.textAlignment = .center
        return label
    }()
    private let subTitle = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.text = "Todos los campos son obligatorios. Podrás modificar tus datos más adelante, con excepción del correo electrónico."
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    private lazy var name = {
        let text = UITextField()
        text.placeholder = "Nombre Completo"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var phone = {
        let text = UITextField()
        text.placeholder = "Teléfono a 10 dígitos: 55 1234-1984"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.keyboardType = .phonePad
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var address = {
        let text = UITextField()
        text.placeholder = "Escribe tu dirección completa"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.addAction(UIAction(handler: { [weak self] _ in
            guard let text = text.text else { return }
            self?.locationManager.searchText = text
        }), for: .editingChanged)
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var currentLocation = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemGreen
        button.setTitle("   Usar ubicación actual", for: .normal)
        button.setImage(UIImage(systemName: "location.north.circle.fill"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(currentLocationButtonAction), for: .touchUpInside)
        return button
    }()
    lazy private var places = {
        let table = UITableView(frame: .init(), style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.backgroundColor = .systemBackground
        table.heightAnchor.constraint(equalToConstant: 150).isActive = true
        table.widthAnchor.constraint(equalToConstant: 340).isActive = true
        table.isHidden = true
        return table
    }()
    private lazy var email = {
        let text = UITextField()
        text.placeholder = "ejemplo@correo.com"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.keyboardType = .emailAddress
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var password = {
        let text = UITextField()
        text.placeholder = "Contraseña_21"
        text.font = .systemFont(ofSize: 17)
        text.isSecureTextEntry = true
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var signUpButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Registrar Cuenta", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signUpButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var signInButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("¿Ya tienes cuenta? Inicia Sesión", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signInButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var mainUIStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [title, subTitle, name, phone, address, places, currentLocation, email, password, signUpButton, signInButton])
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
    private lazy var keyboardToolBar = {
        let toolBar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Listo", style: .plain, target: self, action: #selector(hideKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [flexSpace, flexSpace, doneButton]
        toolBar.sizeToFit()
        return toolBar
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
        fetchedPlacesSubscriber = locationManager.$fetchedPlaces.sink(receiveValue: { [weak self] places in
            guard let places else { return }
            if places.isEmpty {
                DispatchQueue.main.async {
                    self?.places.isHidden = true
                }
            } else {
                DispatchQueue.main.async {
                    self?.places.reloadData()
                    self?.places.isHidden = false
                }
            }
        })
    }
    
    @objc private func hideKeyboard() {
        viewController.view.endEditing(true)
    }
    
    @objc private func currentLocationButtonAction() {
        viewController.show(UINavigationController(rootViewController: MapViewController(locationManager: locationManager)), sender: viewController)
        confirmLocationSubscriber = locationManager.$confirmLocation.sink(receiveValue: { [weak self] confirm in
            guard let location = self?.locationManager.pickedPlaceMark, confirm else { return }
            if let dir1 = location.name, let dir2 = location.subLocality, let dir3 = location.locality, let dir4 = location.administrativeArea {
                self?.address.text = "\(dir1) \(dir2), \(dir3), \(dir4)"
            } else {
                self?.address.text = location.name
            }
            self?.places.isHidden = true
        })
    }
    
    @objc private func signInButtonAction() {
        dismissWithTransition(toPosition: -700, inSeconds: 0.5)
    }
    
    @objc private func signUpButtonAction() {
        loginAPI = EmailAuthAPI()
        DispatchQueue.main.async { [weak self] in
            self?.busy.startAnimating()
            self?.signUpButton.isEnabled = false
            self?.signInButton.isEnabled = false
        }
        guard let name = name.text, let phone = phone.text, let address = address.text, let email = email.text, let password = password.text else { return }
        loginAPI?.signUp(userData: [name, phone, address, email, password]) { [weak self] result in
            self?.busy.stopAnimating()
            switch result {
            case .success(_) :
                self?.viewModel.newUser(name: name, phone: phone, address: address, email: email)
                self?.signUpUIResult.image = UIImage(systemName: "checkmark.circle")
                self?.signUpUIResult.tintColor = .green
                self?.signUpUIResult.isHidden = false
                self?.dismiss(toPosition: -700, inSeconds: 0.5)
            case .failure(let error) :
                print(error)
                self?.signUpUIResult.image = UIImage(systemName: "x.circle")
                self?.signUpUIResult.tintColor = .red
                self?.signUpUIResult.isHidden = false
                self?.signUpButton.isEnabled = true
                self?.signInButton.isEnabled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.signUpUIResult.isHidden = true
                }
            }
        }
    }
    
    func dismissWithTransition(toPosition pixels: Double, inSeconds time: Double) {
        UIView.animate(withDuration: time) { [weak self] in
            self?.mainUIStackCenterXAnchor.constant = pixels
            self?.viewController.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let vc = self?.viewController, let delegate = self?.delegate else { return }
            self?.delegate.changeView(to: LoginWithEmailView(viewController: vc, delegate: delegate), fromPosition: (pixels * -1), inSeconds: time)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let places = locationManager.fetchedPlaces else { return 0 }
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let locations = locationManager.fetchedPlaces else { return UITableViewCell() }
        let cell = places.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cellConfig = cell.defaultContentConfiguration()
        cellConfig.image = UIImage(systemName: "mappin.circle.fill")
        cellConfig.text = locations[indexPath.row].name
        if let dir1 = locations[indexPath.row].subLocality, let dir2 = locations[indexPath.row].locality, let dir3 = locations[indexPath.row].administrativeArea {
            cellConfig.secondaryText = "\(dir1), \(dir2) \(dir3)"
        } else {
            cellConfig.secondaryText = locations[indexPath.row].locality
        }
        cell.contentConfiguration = cellConfig
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let locations = locationManager.fetchedPlaces else { return }
        if let dir1 = locations[indexPath.row].name, let dir2 = locations[indexPath.row].subLocality, let dir3 = locations[indexPath.row].locality, let dir4 = locations[indexPath.row].administrativeArea {
            address.text = "\(dir1) \(dir2), \(dir3), \(dir4)"
        } else {
            address.text = locations[indexPath.row].name
        }
        places.isHidden = true
    }
  
}

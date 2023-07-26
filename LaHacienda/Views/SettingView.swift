//
//  SettingView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit
import FirebaseAuth
import Combine

class SettingView: NSObject, TabViewService, UITableViewDataSource, UITableViewDelegate {
    
    init(viewController: UIViewController, delegate: TabViewDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    deinit {
        userDocumentSubscriber.cancel()
        fetchedPlacesSubscriber?.cancel()
        print("SE DESTRUYÓ SETTING VIEW")
    }
    
    unowned var viewController: UIViewController
    let delegate: TabViewDelegate
    var loginAPI: LoginService?
    let viewModel = SettingViewModel()
    private let currentUserEmail = {
        guard let email = Auth.auth().currentUser?.displayName else { return "" }
        return email
    }()
    var currentUser: LaHaciendaUser?
    lazy var userDocumentSubscriber = viewModel.userDocumentPublisher.sink { completion in
        switch completion {
        case .failure(let error):
            print(error)
        case .finished:
            print("TERMINÓ LA SUSCRIPCIÓN USER DOCUMENT SETTING VIEW")
        }
    } receiveValue: { [weak self] user in
        self?.currentUser = user
        self?.name.text = user.name
        self?.phone.text = user.phone
        self?.address.text = user.address
    }
    private var pickedPlaceMarkSubscriber: AnyCancellable?
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
    lazy private var name = {
        let text = CustomSettingUITextField()
        text.placeholder = "Nombre Completo"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.isEnabled = false
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.setOnTextChangeListener { [weak self] in
            guard let newValue = text.text, let currentUser = self?.currentUser else { return }
            self?.viewModel.updateUser(currentUser, newValue: newValue, atField: "name")
        }
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    lazy private var phone = {
        let text = CustomSettingUITextField()
        text.placeholder = "Teléfono a 10 dígitos: 55 1234-1984"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.isEnabled = false
        text.keyboardType = .phonePad
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.setOnTextChangeListener { [weak self] in
            guard let newValue = text.text, let currentUser = self?.currentUser else { return }
            self?.viewModel.updateUser(currentUser, newValue: newValue, atField: "phone")
        }
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    lazy private var address = {
        let text = CustomSettingUITextField()
        text.placeholder = "Escribe tu dirección completa"
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.isEnabled = false
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.setOnTextChangeListener { [weak self] in
            guard let newValue = text.text, let currentUser = self?.currentUser else { return }
            self?.viewModel.updateUser(currentUser, newValue: newValue, atField: "address")
        }
        text.addAction(UIAction(handler: { [weak self] _ in
            guard let text = text.text else { return }
            self?.locationManager.searchText = text
        }), for: .editingChanged)
        text.inputAccessoryView = keyboardToolBar
        return text
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
    private let email = {
        let text = UITextField()
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .center
        text.isEnabled = false
        text.textColor = .systemGray
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return text
    }()
    private lazy var signOutButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Cerrar Sesión", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(signOutButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var mainUIStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [name, phone, address, places, currentLocation, email, signOutButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        return stack
    }()
    private let busy = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.backgroundColor = UIColor(white: 1, alpha: 0.5)
        activityIndicator.layer.cornerRadius = 5
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
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
            mainUIStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mainUIStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            busy.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            busy.centerXAnchor.constraint(equalTo: container.centerXAnchor)])
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
    
    func fetchData() {
        DispatchQueue.main.async { [weak self] in
            self?.busy.startAnimating()
        }
        viewModel.fetchUser(userEmail: currentUserEmail) { [weak self] result in
            switch result {
            case .success(let user):
                self?.busy.stopAnimating()
                self?.currentUser = user
                self?.name.text = user.name
                self?.name.isEnabled = true
                self?.phone.text = user.phone
                self?.phone.isEnabled = true
                self?.address.text = user.address
                self?.address.isEnabled = true
                self?.email.text = user.email
                let _ = self?.userDocumentSubscriber
            case .failure(let error):
                print(error)
                self?.busy.stopAnimating()
            }
        }
    }
    
    @objc private func currentLocationButtonAction() {
        viewController.show(MapViewController(locationManager: locationManager), sender: viewController)
        confirmLocationSubscriber = locationManager.$confirmLocation.sink(receiveValue: { [weak self] confirm in
            guard let location = self?.locationManager.pickedPlaceMark, confirm else { return }
            if let dir1 = location.name, let dir2 = location.subLocality, let dir3 = location.locality, let dir4 = location.administrativeArea {
                self?.address.text = "\(dir1) \(dir2), \(dir3), \(dir4)"
            } else {
                self?.address.text = location.name
            }
            self?.places.isHidden = true
            self?.address.becomeFirstResponder()
        })
    }
    
    @objc private func hideKeyboard() {
        viewController.view.endEditing(true)
    }
    
    @objc private func signOutButtonAction() {
        loginAPI = EmailAuthAPI()
        DispatchQueue.main.async { [weak self] in
            self?.busy.startAnimating()
            self?.signOutButton.isEnabled = false
        }
        loginAPI?.logOut { [weak self] result in
            self?.busy.stopAnimating()
            switch result {
            case .success(_) :
                self?.delegate.logOut(to: LoginViewController())
            case .failure(_) :
                break
            }
        }
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
        address.becomeFirstResponder()
        places.isHidden = true
    }
}

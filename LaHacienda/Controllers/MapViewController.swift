//
//  MapViewControllet.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit
import MapKit
import Combine

class MapViewController: UIViewController, MKMapViewDelegate {
    
    convenience init(locationManager: LocationManager) {
        self.init()
        self.locationManager = locationManager
    }
    
    deinit {
        print("SE DESTRUYÓ MAP VIEW CONTROLLER")
    }
    
    private var locationManager: LocationManager?
    private let mapView = MKMapView()
    private var newPlacemarkSubscriptor: AnyCancellable?
    private let displayLocation = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 10
        return view
    }()
    private let location = {
        let fakeButton = UIButton(type: .system)
        fakeButton.translatesAutoresizingMaskIntoConstraints = false
        fakeButton.setTitle("Ubicación ficticia", for: .normal)
        fakeButton.setImage(UIImage(systemName: "mappin.circle.fill"), for: .normal)
        var config = UIButton.Configuration.borderless()
        config.subtitle = "Localidad ficticia"
        config.titleAlignment = .center
        fakeButton.configuration = config
        fakeButton.tintColor = UIColor.label
        fakeButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        fakeButton.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return fakeButton
    }()
    private lazy var confirm = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Confirmar ubicación", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(confirmLocation), for: .touchUpInside)
        return button
    }()
    private lazy var confirmUIStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [location, confirm])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 5
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        mapView.frame = .init(x: 0, y: view.safeAreaInsets.top, width: view.frame.size.width, height: view.frame.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
        displayLocation.frame = .init(x: 0, y: view.frame.maxY - 150, width: view.frame.size.width, height: 150)
    }
    
    func setup() {
        title = "Ubicación"
        tabBarController?.tabBar.isHidden = true
        view.backgroundColor = .systemBackground
        view.addSubview(mapView)
        view.addSubview(displayLocation)
        displayLocation.addSubview(confirmUIStack)
        NSLayoutConstraint.activate([confirmUIStack.centerXAnchor.constraint(equalTo: displayLocation.centerXAnchor), confirmUIStack.topAnchor.constraint(equalTo: displayLocation.topAnchor)])
        mapView.delegate = self
        newPlacemarkSubscriptor = locationManager?.$pickedPlaceMark.sink(receiveValue: { [weak self] place in
            if let place {
                self?.location.setTitle(place.name, for: .normal)
                if let dir1 = place.subLocality, let dir2 = place.locality, let dir3 = place.administrativeArea {
                    self?.location.configuration?.subtitle = "\(dir1), \(dir2) \(dir3)"
                } else {
                    self?.location.configuration?.subtitle = place.locality
                }
            }
        })
        if let coordinate = locationManager?.userLocation?.coordinate {
            mapView.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            addDraggablePin(coordinate: coordinate)
            updatePlacemark(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        locationManager?.confirmLocation = false
    }
    
    func addDraggablePin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Tus pedidos se entregarán aquí"
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "DeliveryPin")
        marker.isDraggable = true
        marker.canShowCallout = false
        return marker
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let newLocation = view.annotation?.coordinate else { return }
        locationManager?.pickedLocation = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
        updatePlacemark(location: CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude))
    }
    
    func updatePlacemark(location: CLLocation){
        Task {
            do {
                guard let place = try await reverseLocationCoordinates(location: location) else { return }
                locationManager?.pickedPlaceMark = place
            } catch {
                
            }
        }
    }
    
    func reverseLocationCoordinates(location: CLLocation) async throws -> CLPlacemark? {
        let place = try await CLGeocoder().reverseGeocodeLocation(location).first
        return place
    }
    
    @objc func confirmLocation() {
        locationManager?.confirmLocation = true
        navigationController?.popViewController(animated: true)
        dismiss(animated: true)
    }
}

//
//  LocationManager.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let manager = CLLocationManager()
    @Published var searchText = ""
    var cancellable: AnyCancellable?
    @Published var fetchedPlaces: [CLPlacemark]?
    @Published var userLocation: CLLocation?
    @Published var pickedLocation: CLLocation?
    @Published var pickedPlaceMark: CLPlacemark?
    @Published var confirmLocation: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        cancellable = $searchText.debounce(for: .seconds(0.5), scheduler: DispatchQueue.main).removeDuplicates().sink(receiveValue: { [weak self] value in
            self?.fetchPlaces(value: value)
        })
    }
    
    func fetchPlaces(value: String) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = value.lowercased()
                let response = try await MKLocalSearch(request: request).start()
                fetchedPlaces = response.mapItems.compactMap({ item -> CLPlacemark? in
                    return item.placemark
                })
            } catch {
                fetchedPlaces?.removeAll()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        userLocation = currentLocation
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways: manager.requestLocation()
        case .authorizedWhenInUse: manager.requestLocation()
        case .denied: handleLocationError()
        case .notDetermined: manager.requestWhenInUseAuthorization()
        default: ()
        }
    }
    
    func handleLocationError() {
        
    }
    
}

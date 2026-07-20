import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var location: CLLocation?
    @Published var cityName: String?
    @Published var countryName: String?
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionAndLocation() {
        errorMessage = nil
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            errorMessage = "La posizione è disattivata. Puoi scegliere una città manualmente."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined, .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        CLGeocoder().reverseGeocodeLocation(
            newLocation,
            preferredLocale: Locale(identifier: "it_IT")
        ) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let placemark = placemarks?.first {
                    self.cityName =
                        placemark.locality ??
                        placemark.subAdministrativeArea ??
                        placemark.administrativeArea ??
                        "Posizione attuale"

                    self.countryName =
                        placemark.country ??
                        placemark.isoCountryCode ??
                        ""
                } else {
                    self.cityName = "Posizione attuale"
                    self.countryName = ""
                    self.errorMessage = error?.localizedDescription
                }

                // Pubblica la posizione soltanto dopo aver ricavato città e Paese.
                // ContentView riceve quindi il nome corretto già al primo avvio.
                self.location = newLocation
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }


    func requestInitialLocation() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
}

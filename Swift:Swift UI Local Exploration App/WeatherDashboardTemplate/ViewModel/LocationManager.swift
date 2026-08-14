//
//  LocationManager.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation
import CoreLocation
@preconcurrency import MapKit


@MainActor
final class LocationManager {

    func geocodeAddress(_ address: String) async throws -> (name: String, lat: Double, lon: Double) {
        // Uses `CLGeocoder` to convert a string address into geographic coordinates.
        // Extracts the name, latitude, and longitude from the first resulting placemark.
        // Throws a `WeatherMapError.geocodingFailed` if no valid location can be found.

        // DUMMY RETURN TO SATISFY COMPILER
        
        let geocoder = CLGeocoder()
        
        do{
            let placemarks = try await geocoder.geocodeAddressString(address)
            
            guard let placemark = placemarks.first, let location = placemark.location else {
                throw WeatherMapError.geocodingFailed(address)
            }
            
            let name = placemark.name ?? address
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            return (name, lat, lon)
        } catch let error as WeatherMapError {
            throw error
        } catch {
            throw WeatherMapError.geocodingFailed(address)
        }
    }

    func findPOIs(lat: Double, lon: Double, limit: Int = 5) async throws -> [AnnotationModel] {
        // Uses `MKLocalSearch` to find Points of Interest (POIs), specifically "Tourist Attractions," within a small region around the given latitude and longitude.
        // Executes the search request.
        // Maps the `MKMapItem` results into an array of `AnnotationModel`s, filtering out any without a name.
        // Limits the final array size to the specified `limit`.

        // DUMMY RETURN TO SATISFY COMPILER
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Tourist Attractions"
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            
            let annotations = response.mapItems.compactMap{item -> AnnotationModel? in guard let name = item.name else { return nil }; return AnnotationModel(name: name, latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            }
            
            return Array(annotations.prefix(limit))
        } catch {
            throw WeatherMapError.networkError(error)
        }
    }
}

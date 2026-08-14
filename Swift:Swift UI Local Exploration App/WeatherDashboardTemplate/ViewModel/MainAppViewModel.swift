//
//  MainAppViewModel.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData
import MapKit

@MainActor
final class MainAppViewModel: ObservableObject {
    @Published var query = ""
    @Published var currentWeather: Weather?
    @Published var forecast: [Weather] = []
    @Published var pois: [AnnotationModel] = []
    @Published var mapRegion = MKCoordinateRegion()
    @Published var visited: [Place] = []
    @Published var isLoading = false
    @Published var appError: WeatherMapError?
    @Published var activePlaceName: String = ""
    private let defaultPlaceName = "London"
    @Published var selectedTab: Int = 0
    
    @Published var currentConditions: Current?
    @Published var dailyForcast: [Daily] = []
    
    /// Create and use a WeatherService model (class) to manage fetching and decoding weather data
    private let weatherService = WeatherService()
    
    /// Create and use a LocationManager model (class) to manage address conversion and tourist places
    private let locationManager = LocationManager()
    
    /// Use a context to manage database operations
    private let context: ModelContext
    
    init(context: ModelContext) {
        // Initialize the ModelContext and attempt to fetch previously visited places from SwiftData, sorted by most recent use.
        // If no visited places exist (first launch), load the default location.
        // Otherwise, load the most recently used place.
        self.context = context
        
        // Corrected FetchDescriptor to include sorting by 'lastUsedAt' in reverse order.
        if let results = try? context.fetch(
            FetchDescriptor<Place>(sortBy: [SortDescriptor(\Place.lastUsedAt, order: .reverse)])
        ) {
            self.visited = results
        }
        
        // First launch: no data → perform full London setup
        if visited.isEmpty {
            Task {
                await loadDefaultLocation()
            }
        } else if let mostRecent = visited.first {
            // Otherwise, load most recently used place
            Task {
                await loadLocation(fromPlace: mostRecent)
            }
        }
    }
    
    func submitQuery() {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            appError = .missingData(message: "Please enter a valid location.")
            return
        }
        Task {
            do {
                // MARK: call loadLocation(byName:)
                try await loadLocation(byName: city)
                query = ""
            } catch {
                appError = .networkError(error)
            }
        }
    }
    func loadDefaultLocation() async {
        // Attempts to select and load the hardcoded default location name.
        // If an error occurs during selection, sets an app error.
        do {
            try await loadLocation(byName: defaultPlaceName)
        } catch {
            appError = .missingData(message: "Failed to load default location: London")
        }
    }
    
    func search() async throws {
        // If the query is not empty, calls `select(placeNamed:)` with the current query string.
    }
    
    /// Validate weather before saving a new place; create POI children once.
    func loadLocation(byName name: String) async throws {
        // Sets loading state, then attempts to load data for the given place name.
        // 1. Checks if the place is already in `visited` and, if so, loads all data for the existing `Place` object, updates its `lastUsedAt`, and saves the context.
        // 2. Otherwise, geocodes the fresh place name using `locationManager`.
        // 3. Fetches weather data using `weatherService` as a fail-fast check.
        // 4. Finds Points of Interest (POIs) using `locationManager`, converts them to `AnnotationModel`s, and associates them with the new `Place`.
        // 5. Inserts the new `Place` into the `visited` array and saves the context.
        // 6. Updates UI by setting `pois`, `activePlaceName`, and focusing the map.
        // 7. If any step fails, logs the error and reverts to the default location with an alert.
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let exists = visited.first(where: { $0.name.lowercased() == name.lowercased() }) {
                try await loadAll(for: exists)
                exists.lastUsedAt = .now
                try? context.save()
                appError = .missingData(message: "'\(exists.name)' loaded.")
                return
            }
            
            let geo = try await locationManager.geocodeAddress(name)
            let weathRes = try await weatherService.fetchWeather(lat: geo.lat, lon: geo.lon)
            let anno = try await locationManager.findPOIs(lat: geo.lat, lon: geo.lon)
            
            let place = Place(name: geo.name, latitude: geo.lat, longitude: geo.lon)
            place.annotations = anno
            context.insert(place)
            try? context.save()
            
            visited.insert(place, at: 0)
            currentWeather = weathRes.current.weather.first
            forecast = weathRes.daily.flatMap{$0.weather}
            currentConditions = weathRes.current
            dailyForcast = weathRes.daily
            pois = anno
            activePlaceName = geo.name
            focus(on: CLLocationCoordinate2D(latitude: geo.lat, longitude: geo.lon))
        } catch let error as WeatherMapError {
            await revertToDefaultWithAlert(message: "Can't find '\(name)', Switching to default.")
            throw error
        } catch {
            await revertToDefaultWithAlert(message: "Can't find '\(name)', Switching to default.")
        }
    }
    
    
    func loadLocation(fromPlace place: Place) async{
        // Sets loading state, then attempts to load all data for an existing `Place` object.
        // Updates the place's `lastUsedAt` and saves the context upon success.
        // Catches and sets `appError` for any failure during the load process.
        isLoading = true
        defer { isLoading = false }
        do {
            try await loadAll(for: place)
            place.lastUsedAt = .now
            try? context.save()
        } catch {
            appError = .missingData(message: "Failed to load '\(place.name)'.")
        }
    }
    
    private func revertToDefaultWithAlert(message: String) async {
        // Sets an `appError` with the given message, then calls `loadDefaultLocation()` to switch back to the default.
        appError = .missingData(message: message)
        await loadDefaultLocation()
        
    }
    
    func focus(on coordinate: CLLocationCoordinate2D, zoom: Double = 0.02) {
        // Animates the map region to center on the given coordinate with a specified zoom level (span).
        mapRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))
    }
    
    private func loadAll(for place: Place) async throws {
        // Sets `activePlaceName` and prints a loading message.
        // Always refreshes weather data from the API.
        // Checks if the `Place` object has existing annotations (POIs).
        // If annotations are empty, fetches new POIs via `MKLocalSearch`, converts them to `AnnotationModel`s, adds them to the `Place`, saves the context, and sets `self.pois`.
        // If annotations exist, uses the cached list for `self.pois`.
        // Calls `focus(on:zoom:)` to update the map view.
        // Ensures the place is at the top of the `visited` list (if not already).
        activePlaceName = place.name
        print("Loading data for \(place.name)...")
        
        let weatherRes = try await weatherService.fetchWeather(lat: place.latitude, lon: place.longitude)
        currentWeather = weatherRes.current.weather.first
        forecast = weatherRes.daily.flatMap{$0.weather}
        currentConditions = weatherRes.current
        dailyForcast = weatherRes.daily
        
        if place.annotations.isEmpty {
            let new = try await locationManager.findPOIs(lat: place.latitude, lon: place.longitude)
            place.annotations = new
            try? context.save()
            pois = new
        } else {
            pois = place.annotations
        }
        
        focus(on: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
        
        if let idx = visited.firstIndex(where: {$0.id == place.id}), idx != 0 {
            visited.move(fromOffsets: IndexSet(integer: idx), toOffset: 0)
        }
    }
    
    func delete(place: Place) {
        // Deletes the given `Place` object from the ModelContext and removes it from the `visited` array.
        // Attempts to save the context.
        context.delete(place)
        visited.removeAll{ $0.id == place.id }
        try? context.save()
    }
}

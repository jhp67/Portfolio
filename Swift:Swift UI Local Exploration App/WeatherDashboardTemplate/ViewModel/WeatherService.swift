//
//  WeatherService.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation
@MainActor
final class WeatherService {

    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        // Constructs a URL for the OpenWeatherMap OneCall API using the provided coordinates and API key.
        // Performs an asynchronous network request using URLSession.
        // Validates the HTTP response status code.
        // Decodes the received JSON data into a `WeatherResponse` object, using a specific date decoding strategy.
        // Handles and throws specific `WeatherMapError` types for invalid URL, network failure, invalid response, and decoding errors.

        // DUMMY RETURN TO SATISFY COMPILER - you will have your own when the coding is done
        let apiKey = "51da307464882ccaab111ce152a10cf1"
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&exclude=minutely,alerts&units=metric&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { throw WeatherMapError.invalidURL(urlString)}
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(url)
            print(String(data: data, encoding: .utf8) ?? "")
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherMapError.invalidResponse(statusCode: -1)
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw WeatherMapError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                return try decoder.decode(WeatherResponse.self, from: data)
            } catch {
                throw WeatherMapError.decodingError(error)
            }
        } catch let error as WeatherMapError {
            throw error
        } catch {
            throw WeatherMapError.networkError(error)
        }
    }
}

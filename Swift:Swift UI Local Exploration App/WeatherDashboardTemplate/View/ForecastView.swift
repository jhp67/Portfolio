//
//  ForecastView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import Charts
import SwiftData


import SwiftUI
import Charts   // Include if you plan to show a chart later

// MARK: - Temperature Category
/// Example of how to categorize temperatures for display.
/// Add more cases or adjust logic as needed.
enum TempCategory: String, CaseIterable {
    case cold = "Cold"   // Example category
    case mild = "Mild"
    case warm = "Warm"
    case hot = "Hot"
    
    /// Choose a color to represent this category.
    var color: Color {
        switch self {
        case .cold:
            return .blue
            // TODO: add more cases (e.g., .cool, .warm, .hot) with colors as needed
        case.mild:
            return.green
        case.warm:
            return.yellow
        case.hot:
            return.red
            
        }
    }
    
    /// Convert a Celsius temperature into a category.
    static func from(tempC: Double) -> TempCategory {
        if tempC <= 0 {
            return .cold
        } else if tempC > 0 && tempC <= 10 {
            return .mild
        } else if tempC > 10 && tempC <= 25 {
            return .warm
        } else if tempC > 25 {
            return .hot
        }
        // TODO: add more logic for other ranges (cool, warm, hot)
        return .cold
    }
}

// MARK: - Temperature Data Model
/// A single temperature reading for the chart or list.
private struct TempData: Identifiable {
    let id = UUID()
    let time: Date          // e.g., forecast date
    let type: String        // e.g., "High" or "Low"
    let value: Double       // numeric value
    let category: TempCategory
}

// MARK: - Forecast View
/// Stubbed Forecast View that includes an image placeholder to show
/// what the final view will look like. Replace the image once real data and charts are added.
struct ForecastView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @State private var selectedDay: Daily?
    /// Converts forecast data into chart-friendly entries.
    private var chartData: [TempData] {
        vm.dailyForcast.map { day in
            
            
            TempData(
                time: Date(timeIntervalSince1970: TimeInterval(day.dt)),
                type: "Day",
                value: day.temp.day,
                category: .from(tempC: day.temp.day)
            )
            // TODO: add a "Low" entry or other data points if needed
            
        }
    }
    
    var body: some View {
        ZStack {
            
            LinearGradient (colors: [Color.pink.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            ScrollView {

                VStack{
                    Text("8 Day Forecast - \(vm.activePlaceName)").padding().font(.headline)
                    VStack {
                    
                        Chart(chartData) { item in
                            BarMark(
                                x: .value("Day" ,item.time, unit: .day),
                                y: .value("Temperature", item.value)
                            ).foregroundStyle(item.category.color)
                        }.frame(height: 220)
                    }.padding().background(.white.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack {
                        List(vm.dailyForcast, id: \.dt) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(DateFormatterUtils.formattedDateWithWeekdayAndDay(from: TimeInterval(day.dt)))
                                        Text(day.weather.first?.description.capitalized ?? "").font(.caption)
                                        HStack {
                                            Text("Low: \(Int(day.temp.min))")
                                            Text("High: \(Int(day.temp.max))")
                                        }
                                        
                                    }.foregroundStyle(Color.black)
                                    Spacer()
                                    Text("\(Int(day.temp.day))°C").bold().foregroundStyle(Color.black)
                                }
                            }.listRowBackground(Color.clear)
                        }.scrollContentBackground(.hidden).background(Color.clear)
                    }.frame(height: 400).background(.white.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 20))
                }.padding()
            }
        }.navigationTitle("Forecast").sheet(item: $selectedDay) { day in
            ForecastDetailView(day: day)
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    ForecastView()
        .environmentObject(vm)
}

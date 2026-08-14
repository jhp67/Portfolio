//
//  ForecastDetailView.swift
//  WeatherDashboardTemplate
//
//  Created by James Price
//

import SwiftUI

struct ForecastDetailView: View {
    
    let day: Daily
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: MainAppViewModel
    
    var body: some View {
        
        let advice = WeatherAdviceCategory.from(temp: day.temp.day, description: day.weather.first?.description ?? "")
        
        NavigationStack{
            
            ZStack{
                
                LinearGradient (colors: [Color.pink.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                
                VStack {
                    
                    HStack {
                        Text(vm.activePlaceName).font(.largeTitle).bold()
                        Spacer()
                        Text(DateFormatterUtils.formattedDateTime(from: TimeInterval(day.dt))).font(.subheadline)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(Int(day.temp.day))°C").font(.system(size: 70, weight: .thin))
                            Spacer()
                        }
                        
                        HStack{
                            Text(day.weather.first?.description.capitalized ?? "").font(.title)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "thermometer.low")
                            Text("\(Int(day.temp.min))")
                            Image(systemName: "thermometer.high")
                            Text("\(Int(day.temp.max))")
                        }
                        
                        Divider().padding()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "gauge")
                                Text("Pressure:")
                                Spacer()
                                Text("\(day.pressure) hPa")
                            }
                            HStack {
                                Image(systemName: "sunrise.fill")
                                Text("Sunrise:")
                                Spacer()
                                Text(DateFormatterUtils.formattedDate12Hour(from: TimeInterval(day.sunrise)))
                            }
                            HStack {
                                Image(systemName: "sunset.fill")
                                Text("Sunset:")
                                Spacer()
                                Text(DateFormatterUtils.formattedDate12Hour(from: TimeInterval(day.sunset)))
                            }
                        }
                        
                        Divider().padding()
                        
                        HStack {
                            Image(systemName: advice.icon).font(.system(size: 35)).foregroundColor(advice.color).padding()
                            Text(advice.adviceText).font(.subheadline)
                        }.padding().background(.white.opacity(0.25)).cornerRadius(12)
                    }.padding(25).background(.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                }.padding().navigationTitle("Forecast").navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                }
            }
        }
    }
}


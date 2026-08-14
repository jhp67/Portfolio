//
//  CurrentWeatherView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData


struct CurrentWeatherView: View {
    @EnvironmentObject var vm: MainAppViewModel
    
    var body: some View {
        ZStack{
            
            LinearGradient (colors: [Color.pink.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            if let current = vm.currentConditions {
                
                VStack {
                    
                    let advice = WeatherAdviceCategory.from(temp: current.temp, description: current.weather.first?.description ?? "")
                    
                    HStack {
                        Text(vm.activePlaceName).font(.largeTitle).bold()
                        Spacer()
                        Text(DateFormatterUtils.formattedDateTime(from: TimeInterval(current.dt))).font(.subheadline)
                    }
                    
                    VStack{
                        HStack {
                            Text("\(Int(current.temp.rounded()))°C").font(.system(size: 70, weight: .thin))
                            Spacer()
                        }
                        
                        HStack{
                            Text(current.weather.first?.description.capitalized ?? "").font(.title)
                            Spacer()
                        }
                        
                        Divider().padding()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "gauge")
                                Text("Pressure:")
                                Spacer()
                                Text("\(current.pressure) hPa")
                            }
                            HStack {
                                Image(systemName: "sunrise.fill")
                                Text("Sunrise:")
                                Spacer()
                                Text(DateFormatterUtils.formattedDate12Hour(from: TimeInterval(current.sunrise)))
                            }
                            HStack {
                                Image(systemName: "sunset.fill")
                                Text("Sunset:")
                                Spacer()
                                Text(DateFormatterUtils.formattedDate12Hour(from: TimeInterval(current.sunset)))
                            }
                        }
                        
                        Divider().padding()
                                                
                        HStack {
                            Image(systemName: advice.icon).font(.system(size: 35)).foregroundColor(advice.color).padding()
                            Text(advice.adviceText).font(.subheadline)
                        }.padding().background(.white.opacity(0.25)).cornerRadius(12)
                    }.padding(25).background(.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                }.padding()
            }
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    CurrentWeatherView()
        .environmentObject(vm)
}

//
//  VisitedPLacesView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData


struct VisitedPlacesView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @Environment(\.modelContext) private var context // Not used in body, but kept for completeness
    @State private var loadedPlace: Place?
    @Environment(\.openURL) private var openURL
    
    // MARK:  add local variables for this view
    
    var body: some View {
        ZStack {
            
            LinearGradient (colors: [Color.pink.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            VStack {
                HStack{
                    Text("Visited Places")
                    Spacer()
                    Image(systemName: "mappin.and.ellipse")
                }.padding()
                
                List {
                    ForEach(vm.visited) { place in
                        VStack(alignment: .leading) {
                            Text(place.name).font(.headline)
                            Text("Lat: \(place.latitude, specifier: "%.3f"), Lon: \(place.longitude, specifier: "%.3f")").font(.caption)
                            Text(DateFormatterUtils.formattedDateTime(from: place.lastUsedAt.timeIntervalSince1970)).font(.caption2)
                            
                        }.contentShape(Rectangle()).onTapGesture {
                            Task {
                                await vm.loadLocation(fromPlace: place)
                                loadedPlace = place
                                vm.selectedTab = 0
                            }
                        }.onLongPressGesture {
                            let toSearch = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
                            if let url = URL(string: "https://www.google.com/search?q=\(toSearch)") {
                                openURL(url)
                            }
                        }.listRowBackground(Color.white.opacity(0.25))
                    }.onDelete { offsets in
                        for i in offsets{
                            vm.delete(place: vm.visited[i])
                        }
                    }
                }.scrollContentBackground(.hidden)
            }
        }.alert(item: $loadedPlace) { place in
            Alert(title: Text("Place Loaded"), message: Text("\(place.name) loaded successfully"), dismissButton: .default(Text("Ok")))
        }
    }
}
#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    VisitedPlacesView()
        .environmentObject(vm)
}

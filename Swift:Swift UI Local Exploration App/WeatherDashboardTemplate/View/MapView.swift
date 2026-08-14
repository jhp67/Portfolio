//
//  MapView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData
import MapKit

struct MapView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @State private var camPos: MapCameraPosition = .automatic
    @State private var pTask: Task<Void, Never>?
    @Environment(\.openURL) private var openURL
    
    // MARK:  add other necessary variables
    var body: some View {
        ZStack {
            LinearGradient (colors: [Color.pink.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack {
                Map(position: $camPos) {
                    ForEach(vm.pois) { poi in
                        let coordinate = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
                        Annotation(poi.name, coordinate: coordinate) {
                            Image(systemName: "mappin.circle.fill").font(.title).foregroundStyle(.red).contentShape(Rectangle()).gesture(
                                DragGesture(minimumDistance: 0).onChanged { _ in
                                    if pTask == nil {
                                        pTask = Task {
                                            try? await Task.sleep(for: .seconds(0.5))
                                            guard !Task.isCancelled else { return }
                                            let toSearch = "\(poi.name) \(vm.activePlaceName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? poi.name
                                            if let url = URL(string: "https://www.google.com/search?q=\(toSearch)") {
                                               openURL(url)
                                            }
                                            pTask = nil
                                            
                                        }
                                    }
                                }.onEnded { _ in
                                    if pTask != nil {
                                        pTask?.cancel()
                                        pTask = nil
                                        withAnimation {
                                            camPos = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500))
                                        }
                                    }
                                }
                            )
                            
                        }
                    }
                }
                Text("Tourist attractions near by \(vm.activePlaceName):").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                List(vm.pois) { poi in
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.gray)
                        Text(poi.name)
                    }.contentShape(Rectangle()).onTapGesture {
                        withAnimation {
                            camPos = .region(
                                MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude), span: vm.mapRegion.span))
                        }
                    }.listRowBackground(Color.white.opacity(0.25))
                }.scrollContentBackground(.hidden)
            }
        }.onAppear {
            camPos = .region(vm.mapRegion)
        }.onChange(of: vm.activePlaceName) { _, _ in
            camPos = .region(vm.mapRegion)
        }
    }
}
#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    MapView()
        .environmentObject(vm)
}

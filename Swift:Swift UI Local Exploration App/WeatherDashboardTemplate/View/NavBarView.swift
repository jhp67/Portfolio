//
//  NavBarView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 19/10/2025.
//

import SwiftUI
import SwiftData

struct NavBarView: View {
    @EnvironmentObject var vm: MainAppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 🔍 Search Bar
            HStack {
                TextField("Enter location", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit { vm.submitQuery() } 

                Button {
                    vm.submitQuery()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 3, y: 2)
            .padding(.horizontal)

            // 🌤 Tabs
            TabView(selection: $vm.selectedTab) {
                CurrentWeatherView()
                    .tabItem { Label("Now", systemImage: "sun.max.fill") }
                    .tag(0)

                ForecastView()
                    .tabItem { Label("Forecast", systemImage: "calendar") }
                    .tag(1)

                MapView()
                    .tabItem { Label("Map", systemImage: "map") }
                    .tag(2)

                VisitedPlacesView()
                    .tabItem { Label("Saved", systemImage: "globe") }
                    .tag(3)
            }
            .accentColor(.blue)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .top)

        .overlay {
            if vm.isLoading {
                ProgressView("Loading…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .alert(item: $vm.appError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}



#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    NavBarView()
        .environmentObject(vm)
}

//#Preview("Full Dashboard") {
//    // 👇 This creates a mock ModelContext using your in-memory preview container
//    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
//
//    // 👇 This displays *all* your tab content at once
//    NavBarView()
//        .environmentObject(vm)
//}
//

//
//  ContentView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/9/24.
//

import SwiftUI

struct ContentView: View {

    @State var isAuthenticated = false
    @State var userFullName: String = ""
    @State var userEmail: String = ""
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            if isAuthenticated {
                TabView(selection: $selectedTab) {
                    BathroomMapView()
                        .modelContainer(Bathrooms.preview)
                        .tabItem {
                            if self.selectedTab == 0 {
                                Image(systemName: "map")
                            } else {
                                Image(systemName: "map.fill")
                            }
                            Text("Map")
                        }
                        .tag(0)

                    Leaderboard()
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "star.fill" : "star")
                            Text("Leaderboard")
                        }
                        .tag(1)

                    // My Account Tab - ProfilePage with Sign Out button
                    ProfilePageView(userFullName: $userFullName, userEmail: $userEmail, isAuthenticated: $isAuthenticated)
                        .tabItem {
                            if self.selectedTab == 2 {
                                Image(systemName: "person")
                            } else {
                                Image(systemName: "person.fill")
                            }
                            Text("My Account")
                        }
                        .tag(2)
                }
            } else {
                // If not authenticated, LandingPage
                LandingPageView(isAuthenticated: $isAuthenticated, userFullName: $userFullName, userEmail: $userEmail)

            }
        }
        .onAppear {
            loadUserData()
        }
    }

    func loadUserData() {
        if let savedFullName = UserDefaults.standard.string(forKey: "userFullName"),
           let savedEmail = UserDefaults.standard.string(forKey: "userEmail") {
            userFullName = savedFullName
            userEmail = savedEmail
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }

    func logout() {
        userFullName = ""
        userEmail = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}

#Preview {
    ContentView()
}

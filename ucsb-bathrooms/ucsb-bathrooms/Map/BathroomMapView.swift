//
//  MainMap.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct BathroomMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var bathrooms: [FirestoreManager.Bathroom] = []
    @State private var selectedBathroom: FirestoreManager.Bathroom?
    @State private var isNavigatingToDetail = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 34.4140,
            longitude: -119.8489
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.01,
            longitudeDelta: 0.01
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
                .zIndex(0)

            locationButton
                .zIndex(1)

            if let bathroom = selectedBathroom {
                BathroomPreviewCard(
                    bathroom: bathroom,
                    isNavigatingToDetail: $isNavigatingToDetail
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)
                    )
                )
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedBathroom)
        .task {
            await loadBathrooms()
        }
    }

    // MARK: - View Components

    private var mapLayer: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: bathrooms
        ) { bathroom in
            MapAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: bathroom.location.latitude,
                    longitude: bathroom.location.longitude
                )
            ) {
                BathroomMarker(
                    isSelected: selectedBathroom?.id == bathroom.id
                ) {
                    withAnimation {
                        selectedBathroom = bathroom
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Only dismiss if tapping the map, not a marker
                    if selectedBathroom != nil {
                        withAnimation {
                            selectedBathroom = nil
                        }
                    }
                }
        )
    }

    private var locationButton: some View {
        VStack {
            Button(action: centerOnUser) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse ? .blue : .gray)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var selectedBathroomPreview: some View {
        if let bathroom = selectedBathroom {
            BathroomPreviewCard(
                bathroom: bathroom,
                isNavigatingToDetail: $isNavigatingToDetail
            )
            .transition(.move(edge: .bottom))
        }
    }

    // MARK: - Helper Functions

    private func centerOnUser() {
        locationManager.requestLocationIfNeeded()
        if let location = locationManager.userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
            }
        }
    }

    private func loadBathrooms() async {
        do {
            bathrooms = try await FirestoreManager.shared.getAllBathrooms()
        } catch {
            print("Error loading bathrooms: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct BathroomMarker: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "toilet.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)

                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .rotationEffect(.degrees(180))
                    .offset(y: -5)
            }
            .padding(8)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BathroomPreviewCard: View {
    let bathroom: FirestoreManager.Bathroom
    @Binding var isNavigatingToDetail: Bool

    var body: some View {
        VStack {
            NavigationLink(
                destination: BathroomDetailView(
                    bathroomID: bathroom.id,
                    location: bathroom.name,
                    gender: bathroom.gender
                ),
                isActive: $isNavigatingToDetail
            ) {
                EmptyView()
            }

            Button {
                isNavigatingToDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(bathroom.name)
                            .font(.headline)

                        Spacer()

                        Label(bathroom.gender, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            RatingStars(rating: bathroom.averageRating, starSize: 12)
                            Text(String(format: "%.1f", bathroom.averageRating))
                                .font(.subheadline)
                        }

                        Text("•")
                            .foregroundColor(.gray)

                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("\(bathroom.totalUses) visits")
                                .font(.subheadline)
                        }

                        Spacer()

                        Text("View Details")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
        .padding(.horizontal)
        .padding(.bottom, 49)
        .background(
            Color.clear
        )
    }
}

#Preview {
    BathroomMapView()
        .modelContainer(Bathrooms.preview)
}

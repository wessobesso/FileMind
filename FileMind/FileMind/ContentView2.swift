//
//  ContentView.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-24.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSidebarItem: String? = "Search"

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 12) {
                sidebarButton(title: "Search", systemImage: "magnifyingglass")
                sidebarButton(title: "Settings", systemImage: "gearshape")
                Spacer()
            }
            .frame(width: 70)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Color.black.opacity(0.95))

            Divider()

            ZStack {
                ZStack {
                    switch selectedSidebarItem {
                    case "Search":
                        SearchDashboard()
                    case "Settings":
                        SettingsView()
                    default:
                        Text("Select an option").foregroundColor(.secondary)
                    }

                    if appState.showToast {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Text(appState.toastMessage)
                                    .foregroundColor(.white)
                                    .font(.footnote)

                                Button(action: {
                                    appState.showToast = false
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .opacity(0.7)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(appState.toastColor)
                            .cornerRadius(6)
                            .shadow(radius: 4)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: appState.showToast)
                            .padding(.bottom, 12)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private func sidebarButton(title: String, systemImage: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(selectedSidebarItem == title ? Color.orange : Color.clear)
                .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 60, height: 60)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            selectedSidebarItem = title
        }
    }
}

#Preview { ContentView() }


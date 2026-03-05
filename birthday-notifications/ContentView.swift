//
//  ContentView.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            AllEventsView()
                .tabItem {
                    Label("All", systemImage: "list.bullet")
                }

            GroupsTabView()
                .tabItem {
                    Label("Groups", systemImage: "folder")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Person.self, PersonGroup.self, GiftIdea.self, Event.self], inMemory: true)
}

//
//  SwiftStudyApp.swift
//  SwiftStudy
//
//  Created by oozoofrog on 2023/02/01.
//

import SwiftUI

@main
struct SwiftStudyApp: App {
    let persistenceController = PersistenceController.shared

    let parser = Commits()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(parser)
        }
    }
}

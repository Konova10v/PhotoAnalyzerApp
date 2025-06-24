//
//  PhotoAnalyzerAppApp.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 23.06.2025.
//

import SwiftUI
import SwiftData

@main
struct PhotoAnalyzerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
		.modelContainer(for: StoredImage.self)
    }
}

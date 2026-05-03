//
//  AuraWriterApp.swift
//  AuraWriter
//
//  Created by Trong Nguyen on 1/5/26.
//

import SwiftUI

@main
struct AuraWriterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

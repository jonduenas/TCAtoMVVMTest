//
//  TCAtoMVVMTestApp.swift
//  TCAtoMVVMTest
//
//  Created by Jon Duenas on 6/11/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCAtoMVVMTestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(initialState: RootFeature.State(), reducer: RootFeature.init))
        }
    }
}

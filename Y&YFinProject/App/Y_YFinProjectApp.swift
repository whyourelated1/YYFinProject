//
//  Y_YFinProjectApp.swift
//  Y&YFinProject
//
//  Created by whyourelated on 12/06/25.
//

import SwiftUI
import SwiftData

@main
struct Y_YFinProjectApp: App {
    @AppStorage("accessToken") private var token: String = "wGxyUVjMpXLknl2Av3eqhjxI"
    @AppStorage("userId")     private var userId: Int   = 90
    @State private var splashDone = false

    let container: ModelContainer = {
        let schema = Schema([
            TransactionEntity.self,
            AccountEntity.self,
            CategoryEntity.self,
            TransactionBackupModel.self
        ])
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("main.store")
        let config = ModelConfiguration(schema: schema, url: url)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            let client = NetworkClient(token: token)

            ZStack {
                MainTabView(
                    client: client,
                    accountId: userId,
                    modelContainer: container
                )
                .opacity(splashDone ? 1 : 0)    // прячем, пока идёт сплэш

                // сплэш‑экран с Lottie
                if !splashDone {
                    SplashScreen {
                        withAnimation(.easeOut(duration: 0.3)) {
                            splashDone = true   // скрываем сплэш
                        }
                    }
                }
            }
        }
    }
}

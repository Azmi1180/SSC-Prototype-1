//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import Combine

// MARK: - APP STATE
enum AppState {
    case mainMenu
    case scenarioSelect
    case playing
}

// MARK: - LEVEL DATA MODELS
// Model ini buat mendefinisikan posisi dan properti setiap entitas di level.

struct ClientData: Identifiable {
    let id = UUID()
    var position: CGPoint // Normalized (0.0 - 1.0)
}

struct RouterData: Identifiable {
    let id = UUID()
    var position: CGPoint // Normalized (0.0 - 1.0)
    var rules: [LogicRule] = []
}

struct ServerData: Identifiable {
    let id = UUID()
    var position: CGPoint // Normalized (0.0 - 1.0)
    var acceptedType: PacketType
}

struct LevelData {
    var id: Int
    var title: String
    var subtitle: String
    var clients: [ClientData]
    var routers: [RouterData]
    var servers: [ServerData]
}

// MARK: - GAME CONTROLLER

class GameController: ObservableObject {
    // Navigasi & Progress
    @Published var appState: AppState = .mainMenu
    @Published var unlockedScenarios: Int = 1 // Berapa level yang sudah terbuka
    
    // In-Game State
    @Published var score: Int = 0
    @Published var showLogicMenu: Bool = false
    @Published var currentLevel: LevelData
    @Published var selectedRouterID: UUID? = nil
    @Published var activeRules: [LogicRule] = []
    @Published var serverAnimationTrigger: UUID? = nil
    var onRulesChanged: ((UUID, [LogicRule]) -> Void)?

    // Database Skenario (Level)
    static let allScenarios: [LevelData] = [
        // SCENARIO 1
        LevelData(
            id: 1,
            title: "SCENARIO 01",
            subtitle: "The Localhost (Home Office)",
            clients: [ ClientData(position: CGPoint(x: 0.15, y: 0.5)) ],
            routers: [ RouterData(position: CGPoint(x: 0.5, y: 0.5)) ],
            servers: [
                ServerData(position: CGPoint(x: 0.85, y: 0.25), acceptedType: .video),
                ServerData(position: CGPoint(x: 0.85, y: 0.75), acceptedType: .email)
            ]
        ),
        // SCENARIO 2 (Lebih rumit, misal ada 2 router / server malware) - Placeholder
        LevelData(
            id: 2,
            title: "SCENARIO 02",
            subtitle: "Network Security (Pertahanan Jaringan)",
            clients: [ ClientData(position: CGPoint(x: 0.15, y: 0.5)) ],
            routers: [ RouterData(position: CGPoint(x: 0.4, y: 0.5)), RouterData(position: CGPoint(x: 0.6, y: 0.5)) ],
            servers: [
                ServerData(position: CGPoint(x: 0.85, y: 0.2), acceptedType: .video),
                ServerData(position: CGPoint(x: 0.85, y: 0.5), acceptedType: .email),
                ServerData(position: CGPoint(x: 0.85, y: 0.8), acceptedType: .malware)
            ]
        ),
        // SCENARIO 3 - Placeholder
        LevelData(
            id: 3,
            title: "SCENARIO 03",
            subtitle: "The Backbone (Data Center)",
            clients: [], routers: [], servers: [] // Kosong sementara
        )
    ]

    init() {
        // Set awal ke level 1
        self.currentLevel = GameController.allScenarios[0]
    }
    
    // MARK: - NAVIGATION LOGIC
    func loadScenario(index: Int) {
        self.currentLevel = GameController.allScenarios[index]
        self.score = 0
        self.activeRules.removeAll() // Reset aturan lama
        self.appState = .playing     // Masuk ke game
    }
    
    func exitToMenu() {
        self.appState = .scenarioSelect
        self.showLogicMenu = false
    }
    // MARK: - LOGIC MENU ACTIONS
    
    // Panggil ini saat user men-tap sebuah Router di layar
    func selectRouter(id: UUID) {
        if let router = currentLevel.routers.first(where: { $0.id == id }) {
            self.selectedRouterID = router.id
            self.activeRules = router.rules
            self.showLogicMenu = true
        }
    }
    
    func addRule(color: PacketType, action: RouterAction) {
        guard activeRules.count < 3 else { return }
        let newRule = LogicRule(conditionColor: color, action: action)
        activeRules.append(newRule)
        syncRules()
    }
    
    func removeRule(at index: IndexSet) {
        activeRules.remove(atOffsets: index)
        syncRules()
    }
    
    func clearRules() {
        activeRules.removeAll()
        syncRules()
    }
    
    private func syncRules() {
        guard let routerID = selectedRouterID else { return }
        
        // 1. Simpan perubahan ke dalam memori LevelData
        if let index = currentLevel.routers.firstIndex(where: { $0.id == routerID }) {
            currentLevel.routers[index].rules = activeRules
        }
        
        // 2. Beritahu SpriteKit (GameScene) untuk update logic node fisiknya
        onRulesChanged?(routerID, activeRules)
    }
}

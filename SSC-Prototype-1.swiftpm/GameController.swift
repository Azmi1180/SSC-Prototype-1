//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import Combine

// MARK: - LEVEL DATA MODELS
// Model ini akan mendefinisikan posisi dan properti setiap entitas di level.

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
    var clients: [ClientData]
    var routers: [RouterData]
    var servers: [ServerData]
}

// MARK: - GAME CONTROLLER

class GameController: ObservableObject {
    @Published var score: Int = 0
    @Published var showLogicMenu: Bool = false
    
    // Level yang sedang dimainkan
    @Published var currentLevel: LevelData
    
    // Menyimpan ID router mana yang sedang diklik & diedit
    @Published var selectedRouterID: UUID? = nil
    @Published var serverAnimationTrigger: UUID? = nil
    
    // Rules yang ditampilkan di UI Logic Menu (mengikuti router yang dipilih)
    @Published var activeRules: [LogicRule] = []
    
    // Helper to sync: UI -> Controller -> GameScene
    // Sekarang kita mengirim ID routernya juga agar SpriteKit tau router mana yg diupdate
    var onRulesChanged: ((UUID, [LogicRule]) -> Void)?
    
    
    init() {
        // SETUP DEFAULT LEVEL 1 (Bisa diganti nanti lewat Level Editor)
        // Koordinat Normalisasi (0.0 sampai 1.0) -> Memastikan responsif di semua layar iOS
        self.currentLevel = LevelData(
            clients: [
                ClientData(position: CGPoint(x: 0.15, y: 0.5)) // Kiri tengah
            ],
            routers: [
                RouterData(position: CGPoint(x: 0.5, y: 0.5))  // Tepat di tengah
            ],
            servers: [
                ServerData(position: CGPoint(x: 0.85, y: 0.25), acceptedType: .video), // Kanan Atas
                ServerData(position: CGPoint(x: 0.85, y: 0.75), acceptedType: .email)  // Kanan Bawah
            ]
        )
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

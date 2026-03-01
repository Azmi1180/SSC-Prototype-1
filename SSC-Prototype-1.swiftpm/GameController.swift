//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import Combine

// MARK: - APP STATE ENUM
enum AppState {
    case mainMenu
    case scenarioSelect
    case playing
}

enum CinematicEvent {
    case slowMoZoom
    case spawnOnePacket
    case restoreSpeed
}

// MARK: - LEVEL DATA MODELS
// Struktur data untuk menyimpan konfigurasi setiap skenario

struct ClientData: Identifiable {
    let id = UUID()
    var position: CGPoint // Normalized (0.0 - 1.0)
}

struct RouterData: Identifiable {
    let id = UUID()
    var name: String // Nama untuk ditampilkan di Logic Menu
    var position: CGPoint // Normalized (0.0 - 1.0)
    var rules: [LogicRule] = []
}

struct ServerData: Identifiable {
    let id = UUID()
    var name: String // Nama Server (Video, Email, dsb)
    var position: CGPoint // Normalized (0.0 - 1.0)
    var acceptedType: PacketType
}

struct NodeConnection: Equatable, Identifiable {
    let id = UUID()
    let fromID: UUID
    let toID: UUID
}

struct LevelData {
    var id: Int
    var title: String
    var subtitle: String
    
    // Entitas Level
    var clients: [ClientData]
    var routers: [RouterData]
    var servers: [ServerData]
    
    // Kabel yang ditarik pemain (Awalnya kosong)
    var connections: [NodeConnection] = []
    
    // Batas kesalahan sebelum Game Over
    var maxPacketLoss: Int
}

// MARK: - GAME CONTROLLER (Central Logic)

@MainActor
class GameController: ObservableObject {
    // Navigasi Antar Layar
    @Published var appState: AppState = .mainMenu
    @Published var unlockedScenarios: Int = 1
    
    // Game State (Skor, Menu, Packet Loss)
    @Published var score: Int = 0
    @Published var currentPacketLoss: Int = 0
    @Published var showLogicMenu: Bool = false
    
    // Data Level Saat Ini
    @Published var currentLevel: LevelData
    
    // Logic Editor State
    @Published var selectedRouterID: UUID? = nil
    @Published var activeRules: [LogicRule] = []
    
    // Konfigurasi Gameplay (Dikontrol oleh Scenario Manager)
    @Published var allowedPackets: [PacketType] = [.video]
    
    // Callback Events (Komunikasi ke SpriteKit & SwiftUI)
    var onRulesChanged: ((UUID, [LogicRule]) -> Void)?
    var onLevelStructureChanged: (() -> Void)?
    var onServersSwapped: (() -> Void)?
    var onForceResetScene: (() -> Void)?
        
    var onCinematicEvent: ((CinematicEvent) -> Void)?
    
    // Animation Trigger for Servers (Untuk efek lampu kedip)
    @Published var serverAnimationTrigger: UUID? = nil
    
    // Scenario Manager
    var scenario1: Scenario1Manager!
    // var scenario2: Scenario2Manager! (Nanti bisa ditambah)
        

    // MARK: - INITIALIZATION
    init() {
        // Placeholder Level (Akan ditimpa saat loadScenario dipanggil)
        self.currentLevel = LevelData(
            id: 0, title: "LOADING", subtitle: "",
            clients: [], routers: [], servers: [], connections: [], maxPacketLoss: 5
        )
        
        // Inisialisasi Manager
        self.scenario1 = Scenario1Manager(controller: self)
    }
    
    // MARK: - SCENARIO MANAGEMENT
    // Database Skenario (Metadata Saja, Detail di-load oleh Manager masing-masing)
    static let allScenarios: [LevelData] = [
        LevelData(id: 1, title: "SCENARIO 01", subtitle: "The Localhost", clients: [], routers: [], servers: [], maxPacketLoss: 5),
        LevelData(id: 2, title: "SCENARIO 02", subtitle: "Network Security", clients: [], routers: [], servers: [], maxPacketLoss: 3),
        LevelData(id: 3, title: "SCENARIO 03", subtitle: "The Backbone", clients: [], routers: [], servers: [], maxPacketLoss: 3)
    ]
    
    @MainActor func loadScenario(index: Int) {
        self.score = 0
        self.currentPacketLoss = 0
        self.activeRules.removeAll()
        self.selectedRouterID = nil
        
        onForceResetScene?()
        
        if index == 0 {
            scenario1.startGame()
        } else {
            print("Scenario \(index + 1) not implemented yet.")
        }
        
        withAnimation {
            self.appState = .playing
        }
    }
    
    func exitToMenu() {
        withAnimation {
            self.appState = .scenarioSelect
            self.showLogicMenu = false
            self.dismissDialogue()
        }
    }

    // MARK: - LOGIC MENU ACTIONS
    func selectRouter(id: UUID) {
        if let router = currentLevel.routers.first(where: { $0.id == id }) {
            self.selectedRouterID = router.id
            self.activeRules = router.rules
            withAnimation {
                self.showLogicMenu = true
            }
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
    
    private func syncRules() {
        guard let routerID = selectedRouterID else { return }
        
        // Simpan ke data level
        if let index = currentLevel.routers.firstIndex(where: { $0.id == routerID }) {
            currentLevel.routers[index].rules = activeRules
        }
        
        // Kirim ke SpriteKit
        onRulesChanged?(routerID, activeRules)
    }
    
    // MARK: - CONNECTION MANAGEMENT (CABLE DRAG)
    func addConnection(from: UUID, to: UUID) {
        if !currentLevel.connections.contains(where: { $0.fromID == from && $0.toID == to }) {
            let newConnection = NodeConnection(fromID: from, toID: to)
            currentLevel.connections.append(newConnection)
            onLevelStructureChanged?()                        
            scenario1.checkCableProgress()
        }
    }
    
    // MARK: - PACKET LOSS & GAME OVER
    func triggerPacketLoss() {
        currentPacketLoss += 1
        
        // Cek Kondisi Kalah
        if currentPacketLoss >= currentLevel.maxPacketLoss {
            showDialogue("CRITICAL FAILURE!\nMaximum packet loss reached. The network has collapsed.\n\nSYSTEM REBOOTING...") { [weak self] in
                self?.exitToMenu()
            }
        }
    }

    // MARK: - GLOBAL DIALOGUE SYSTEM
    @Published var dialogueMessage: String? = nil
    @Published var isPausedForDialogue: Bool = false
    private var onDialogueDismissed: (() -> Void)? = nil
    
    func showDialogue(_ message: String, onDismiss: (() -> Void)? = nil) {
        withAnimation {
            self.dialogueMessage = message
            self.isPausedForDialogue = true
            self.onDialogueDismissed = onDismiss
        }
    }
    
    func dismissDialogue() {
        withAnimation {
            self.dialogueMessage = nil
            self.isPausedForDialogue = false
        }
        // Jalankan callback setelah animasi selesai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.onDialogueDismissed?()
            self.onDialogueDismissed = nil
        }
    }
}


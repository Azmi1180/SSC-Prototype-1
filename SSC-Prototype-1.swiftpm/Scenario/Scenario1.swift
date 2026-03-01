//
//  Scenario1Manager.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 25/02/26.
//


import SwiftUI
import Combine

enum ScenarioTooltip {
    case none
    case dragCableClientToRouter
    case dragCableRouterToServer
    case configureRouter
}

@MainActor
class Scenario1Manager: ObservableObject {
    weak var controller: GameController?
    
    @Published var activeTooltip: ScenarioTooltip = .none
    @Published var currentDay: Int = 1
    @Published var timeRemaining: Int = 20
    @Published var spawnRate: TimeInterval = 3.0
    
    private var timer: AnyCancellable?
    
    init(controller: GameController) {
        self.controller = controller
    }
    
    func startGame() {
        startDay1()
    }
    
    // MARK: - DAY 1 LOGIC
    func startDay1() {
        currentDay = 1
        timeRemaining = 20
        spawnRate = 3.0
                
        activeTooltip = .none
        controller?.allowedPackets = [.video]
                
        controller?.currentLevel = LevelData(
            id: 1, title: "SCENARIO 01", subtitle: "The Localhost",
            clients: [ ClientData(position: CGPoint(x: 0.15, y: 0.5)) ],
            routers: [ RouterData(name: "MAIN_ROUTER", position: CGPoint(x: 0.5, y: 0.5)) ],
            servers: [ ServerData(name: "VIDEO SERVER", position: CGPoint(x: 0.85, y: 0.25), acceptedType: .video) ],
            connections: [],
            maxPacketLoss: 5
        )
                
        controller?.onLevelStructureChanged?()
                
        controller?.showDialogue("DAY 1: ONBOARDING\n\nWelcome to the job.\n\nFirst, we need physical infrastructure. Drag a cable from the USER to the ROUTER.") { [weak self] in
            
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            self?.activeTooltip = .dragCableClientToRouter

                            self?.controller?.objectWillChange.send()
                        }
                    }
                }
    }
    
    // MARK: - PROGRESSION CHECKS (Dipanggil dari GameScene & GameController)
    
    // Fungsi ini dipanggil saat pemain berhasil menarik kabel
    func checkCableProgress() {
        guard currentDay == 1 else { return }
        let connections = controller?.currentLevel.connections.count ?? 0
        
        if connections == 1 && activeTooltip == .dragCableClientToRouter {
            // Kabel 1 selesai, lanjut minta Kabel 2
            withAnimation {
                activeTooltip = .dragCableRouterToServer
                controller?.objectWillChange.send()
            }
        }
        else if connections == 2 && activeTooltip == .dragCableRouterToServer {
            // Kabel 2 selesai, lanjut minta Configure Router
            withAnimation {
                activeTooltip = .configureRouter
                controller?.objectWillChange.send()
            }
            startTimer()
        }
    }
    
    // Fungsi ini dipanggil saat pemain mengklik Router
    func checkRouterClicked() {
        if activeTooltip == .configureRouter {
            withAnimation {
                activeTooltip = .none
                controller?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - DAY 2 & 3 LOGIC (Normal Flow)
    func startDay2() {
        currentDay = 2
        timeRemaining = 20
        spawnRate = 2.0
        activeTooltip = .none // Pastikan tooltip bersih
        
        controller?.allowedPackets = [.video, .email]
        controller?.currentLevel.servers.append(
            ServerData(name: "EMAIL SERVER", position: CGPoint(x: 0.85, y: 0.75), acceptedType: .email)
        )
        controller?.onLevelStructureChanged?()
        
        controller?.showDialogue("DAY 2: EXPANSION\n\nWe added an Email Server (Blue).\nUpdate your router configuration! And don't forget to wire it up.") { [weak self] in
            self?.startTimer()
        }
    }
    
    func startDay3() {
        currentDay = 3
        timeRemaining = 20
        spawnRate = 1.2
        activeTooltip = .none
        
        controller?.allowedPackets = [.video, .email, .malware]
        
        controller?.showDialogue("DAY 3: SECURITY ALERT\n\nMalware detected (Green).\nConfigure the firewall to DROP green packets immediately!") { [weak self] in
            self?.startTimer()
        }
    }
        
    
    // MARK: - TIMER
    func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, let controller = self.controller else { return }
            
            if !controller.isPausedForDialogue && !controller.showLogicMenu {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    controller.objectWillChange.send()
                } else {
                    self.advanceDay()
                }
            }
        }
    }
    
    func advanceDay() {
        timer?.cancel()
        if currentDay == 1 { startDay2() }
        else if currentDay == 2 { startDay3() }
        else {
            controller?.showDialogue("SHIFT COMPLETE.\nFinal Score: \(controller?.score ?? 0)") { [weak self] in
                self?.controller?.exitToMenu()
            }
        }
    }
}

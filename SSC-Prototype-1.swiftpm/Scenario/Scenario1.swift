//
//  Scenario1Manager.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 25/02/26.
//


import SwiftUI
import Combine

@MainActor
class Scenario1Manager: ObservableObject {
    weak var controller: GameController?
    
    @Published var currentDay: Int = 1
    @Published var timeRemaining: Int = 20 // 20 detik per hari agar tidak bosan
    @Published var spawnRate: TimeInterval = 2.5
    
    private var timer: AnyCancellable?
    
    init(controller: GameController) {
        self.controller = controller
    }
    
    func startGame() {
        startDay1()
    }
    
    // MARK: - PROGRESSION LOGIC
    
    func startDay1() {
        currentDay = 1
        timeRemaining = 20
        spawnRate = 3.0
        
        // DAY 1: Hanya ada 1 Server (Video/Merah)
        controller?.allowedPackets = [.video]
        controller?.currentLevel = LevelData(
            id: 1, title: "SCENARIO 01", subtitle: "The Localhost",
            clients: [ ClientData(position: CGPoint(x: 0.15, y: 0.5)) ],
            routers: [ RouterData(position: CGPoint(x: 0.5, y: 0.5)) ],
            servers: [
                ServerData(position: CGPoint(x: 0.85, y: 0.25), acceptedType: .video)
            ]
        )
        controller?.onLevelStructureChanged?()
        
        controller?.showDialogue("DAY 1: ONBOARDING\nWelcome to the job.\n\nThe User wants to watch a video. See that Red Packet? Configure the router to send RED packets to the TOP server.") { [weak self] in
            self?.startTimer()
        }
    }
    
    func startDay2() {
        currentDay = 2
        timeRemaining = 20
        spawnRate = 2.0
        
        // DAY 2: Tambah Email Server (Biru)
        controller?.allowedPackets = [.video, .email]
        controller?.currentLevel.servers.append(
            ServerData(position: CGPoint(x: 0.85, y: 0.75), acceptedType: .email) // Tambah BOTTOM Server
        )
        controller?.onLevelStructureChanged?() // Gambar ulang layar agar server biru muncul
        
        controller?.showDialogue("DAY 2: BUSINESS HOUR\nGood job. Now the User needs to send Emails.\n\nI just plugged in the Blue Server at the bottom. Update your router rules so Blue packets don't crash the Video server!") { [weak self] in
            self?.startTimer()
        }
    }
    
    func startDay3() {
        currentDay = 3
        timeRemaining = 20
        spawnRate = 1.2 // Cepat dan panik
        
        // DAY 3: Masukkan Malware (Hijau), tidak ada server baru, hanya ancaman baru
        controller?.allowedPackets = [.video, .email, .malware]
        
        controller?.showDialogue("DAY 3: SECURITY BREACH\nWARNING! We are detecting Malware (GREEN) on the network!\n\nDo NOT let it reach the servers. Configure a rule to DROP green packets into the firewall immediately!") { [weak self] in
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
                    controller.objectWillChange.send() // Refresh UI
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
            controller?.showDialogue("SHIFT OVER.\nGreat work keeping the network secure.\nFINAL SCORE: \(controller?.score ?? 0)") { [weak self] in
                self?.controller?.exitToMenu()
            }
        }
    }
}

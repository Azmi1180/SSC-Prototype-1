//
//  Scenario1Manager.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 25/02/26.
//


//
//  Scenario1.swift
//  SSC-Prototype
//

import SwiftUI
import Combine

class Scenario1Manager: ObservableObject {
    weak var controller: GameController?
    
    // State Skenario
    @Published var currentDay: Int = 1
    @Published var timeRemaining: Int = 30
    @Published var spawnRate: TimeInterval = 2.5
    
    private var timer: AnyCancellable?
    
    init(controller: GameController) {
        self.controller = controller
    }
    
    func startGame() {
        // Setup Awal Skenario 1
        controller?.currentLevel = LevelData(
            id: 1, title: "SCENARIO 01", subtitle: "The Localhost",
            clients: [ ClientData(position: CGPoint(x: 0.15, y: 0.5)) ],
            routers: [ RouterData(position: CGPoint(x: 0.5, y: 0.5)) ],
            servers: [
                ServerData(position: CGPoint(x: 0.85, y: 0.25), acceptedType: .video), // Top Server
                ServerData(position: CGPoint(x: 0.85, y: 0.75), acceptedType: .email)  // Bottom Server
            ]
        )
        startDay1()
    }
    
    // MARK: - DAY LOGIC
        func startDay1() {
            currentDay = 1
            timeRemaining = 30
            spawnRate = 2.5
            
            // Panggil dialog lewat controller, dan masukkan startTimer() ke dalam closure onDismiss
            controller?.showDialogue("WELCOME TO THE JOB.\nDON'T BREAK THE INTERNET.\n\nRED = VIDEO\nBLUE = TEXT\n\nConfigure the router (center) to send RED UP and BLUE DOWN.") { [weak self] in
                self?.startTimer()
            }
        }
        
        func startDay2() {
            currentDay = 2
            timeRemaining = 30
            spawnRate = 1.2
            controller?.showDialogue("DAY 2: TRAFFIC SURGE.\nVolume is doubling. Ensure no packets hit the wrong server.") { [weak self] in
                self?.startTimer()
            }
        }
        
        func startDay3() {
            currentDay = 3
            timeRemaining = 30
            spawnRate = 1.0
            controller?.showDialogue("DAY 3: MAINTENANCE.\nWe are moving the server racks. Do not stop routing.") { [weak self] in
                self?.executeTheFlip()
                self?.startTimer()
            }
        }
    
    // MARK: - EVENTS
    func executeTheFlip() {
        guard let controller = controller else { return }
        
        // Animasi menukar posisi server di UI
        withAnimation(.easeInOut(duration: 2.0)) {
            let tempPos = controller.currentLevel.servers[0].position
            controller.currentLevel.servers[0].position = controller.currentLevel.servers[1].position
            controller.currentLevel.servers[1].position = tempPos
        }
        
        // Beri tahu SpriteKit untuk memindahkan hitbox fisiknya
        controller.onServersSwapped?()
    }
            
    var onDialogueDismissed: (() -> Void)? = nil    
    
    func startTimer() {
            timer?.cancel()
            timer = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    // Pastikan self dan controller ada
                    guard let self = self, let controller = self.controller else { return }
                    
                    // Cek apakah game tidak sedang di-pause
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
            controller?.showDialogue("SHIFT OVER.\nGood job keeping the net alive.\nSCORE: \(controller?.score ?? 0)") { [weak self] in
                self?.controller?.exitToMenu()
            }
        }
    }
}

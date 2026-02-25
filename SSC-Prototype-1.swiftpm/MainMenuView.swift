//
//  MainMenuView.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 25/02/26.
//


import SwiftUI

struct MainMenuView: View {
    @ObservedObject var controller: GameController
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Judul Game
                VStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan, radius: 10)
                    
                    Text("SECURE SOCKET CONNECTION")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("SYSTEM.BOOT_SEQ() // V 1.0.4")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
                
                // Tombol Main
                Button(action: {
                    withAnimation { controller.appState = .scenarioSelect }
                }) {
                    Text("ACCESS TERMINAL")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .frame(width: 240)
                        .padding(.vertical, 16)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan, lineWidth: 2))
                        .shadow(color: Color.cyan.opacity(0.5), radius: 8)
                }
            }
        }
    }
}

struct ScenarioSelectView: View {
    @ObservedObject var controller: GameController
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { withAnimation { controller.appState = .mainMenu } }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("SELECT SCENARIO")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    // Penyeimbang layout
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding()
                
                // List Skenario
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<GameController.allScenarios.count, id: \.self) { index in
                            let scenario = GameController.allScenarios[index]
                            let isUnlocked = index < controller.unlockedScenarios
                            
                            Button(action: {
                                if isUnlocked {
                                    withAnimation { controller.loadScenario(index: index) }
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // Ikon Status
                                    Image(systemName: isUnlocked ? "play.fill" : "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isUnlocked ? .green : .gray)
                                        .frame(width: 40)
                                    
                                    // Info Level
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scenario.title)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(isUnlocked ? .green : .gray)
                                        
                                        Text(scenario.subtitle)
                                            .font(.system(size: 16, weight: .black, design: .monospaced))
                                            .foregroundColor(isUnlocked ? .white : .gray.opacity(0.5))
                                    }
                                    Spacer()
                                }
                                .padding(20)
                                .background(Color.white.opacity(isUnlocked ? 0.05 : 0.02))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isUnlocked ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: isUnlocked ? Color.green.opacity(0.1) : .clear, radius: 10)
                            }
                            .disabled(!isUnlocked)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
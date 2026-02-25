//
//  ContentView.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    // Setup Scene untuk SpriteKit (Layer Dasar Game)
    var scene: SKScene {
        let scene = GameScene()
        // Menggunakan dimensi layar perangkat
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        scene.gameController = controller
        return scene
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - LAYER 1: GAME WORLD (SpriteKit)
                // Menangani pergerakan paket, server, dan garis track
                SpriteView(scene: scene, isPaused: controller.showLogicMenu)
                    .ignoresSafeArea()
                
                // MARK: - LAYER 2: DYNAMIC ENTITIES (SwiftUI Overlay)
                // Render semua Router secara dinamis berdasarkan data Level
                ForEach(controller.currentLevel.routers) { router in
                    RouterView(controller: controller, routerID: router.id)
                        .scaleEffect(0.5) // Ukuran router (sesuaikan jika terlalu besar/kecil)
                        // Posisi dinamis (konversi dari 0.0-1.0 ke pixel layar)
                        .position(
                            x: router.position.x * geo.size.width,
                            y: router.position.y * geo.size.height
                        )
                        .allowsHitTesting(true)
                }
                
                // 2. Loop semua Server
                ForEach(controller.currentLevel.servers) { server in
                    ServerRackView(controller: controller, serverID: server.id, acceptedType: server.acceptedType)
                        .scaleEffect(0.4)
                        .position(x: server.position.x * geo.size.width, y: server.position.y * geo.size.height)
                }
                
                // Nanti kamu bisa tambahkan ServerView() dan ClientView() di sini
                // dengan ForEach yang sama jika mau full SwiftUI.
                // Sementara ini Server dan Client masih digambar oleh SpriteKit.
                
                // MARK: - LAYER 3: HUD (Score & Info)
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "cpu")
                            Text("RULES: \(controller.activeRules.count)/3")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.yellow)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.yellow, lineWidth: 1))
                        
                        Spacer()
                        
                        Text("SCORE: \(controller.score)")
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Hint Text (Muncul kalau menu tertutup)
                    if !controller.showLogicMenu {
                        Text("// TAP ROUTER NODE TO CONFIGURE")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 20)
                            .transition(.opacity)
                    }
                }
                .zIndex(2) // HUD selalu paling atas dari game
            }
            
            // MARK: - LAYER 4: LOGIC MENU (Popup Modal)
            if controller.showLogicMenu {
                ZStack {
                    // Dimming Background
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { controller.showLogicMenu = false }
                    
                    // The Menu
                    LogicMenu(controller: controller)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                .zIndex(100)
            }
        }
        .statusBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.showLogicMenu)
    }
}

#Preview {
    ContentView()
}

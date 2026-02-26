import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    var body: some View {
        // Sistem Routing Layar
        Group {
            switch controller.appState {
            case .mainMenu:
                MainMenuView(controller: controller)
                    .transition(.opacity)
                
            case .scenarioSelect:
                ScenarioSelectView(controller: controller)
                    .transition(.move(edge: .trailing))
                
            case .playing:
                GamePlayView(controller: controller)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: controller.appState)
        .statusBarHidden(true)
    }
}

// MARK: - TAMPILAN DALAM GAME (Yang sebelumnya ada di ContentView)
struct GamePlayView: View {
    @ObservedObject var controller: GameController
    
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        scene.gameController = controller
        return scene
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // LAYER 1: GAME WORLD (SpriteKit)
                SpriteView(scene: scene, isPaused: controller.showLogicMenu)
                    .ignoresSafeArea()
//                SpriteView(scene: scene)
//                    .ignoresSafeArea()
                
                // LAYER 2: DYNAMIC ENTITIES (Routers & Servers)
                ForEach(controller.currentLevel.routers) { router in
                    RouterView(controller: controller, routerID: router.id)
                        .scaleEffect(0.5)
                        .position(x: router.position.x * geo.size.width, y: router.position.y * geo.size.height)
                }
                
                ForEach(controller.currentLevel.servers) { server in
                    ServerRackView(controller: controller, serverID: server.id, acceptedType: server.acceptedType)
                        .scaleEffect(0.4)
                        .position(x: server.position.x * geo.size.width, y: server.position.y * geo.size.height)
                }
                
                // LAYER 3: HUD (Beserta Tombol Keluar)
                VStack {
                    HStack {
                        Button(action: { controller.exitToMenu() }) {
                            Image(systemName: "stop.circle.fill").font(.title2).foregroundColor(.red)
                        }
                        
                        // DAY & TIMER INDICATOR
                        HStack(spacing: 8) {
                            Text("DAY \(controller.scenario1.currentDay)")
                                .fontWeight(.black)
                                .foregroundColor(.cyan)
                            Text(String(format: "0:%02d", controller.scenario1.timeRemaining))
                                .foregroundColor(.white)
                        }
                        .font(.system(.headline, design: .monospaced))
                        .padding(8)
                        .background(Color.black)
                        .cornerRadius(4)
                        
                        Spacer()
                        
                        Text("SCORE: \(controller.score)")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    Spacer()
                }
                .zIndex(2)
                
                // LAYER 4: LOGIC MENU
                if controller.showLogicMenu {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                            .onTapGesture { controller.showLogicMenu = false }
                        
                        LogicMenu(controller: controller)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    .zIndex(100)
                }
                // MARK: - LAYER 5: DIALOGUE BOX (Pesan dari Bos)
                
                if let messageText = controller.dialogueMessage {
                    ZStack {
                        Color.black.opacity(0.8).ignoresSafeArea() // Gelapkan layar
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.badge.fill").foregroundColor(.cyan)
                                Text("INCOMING TRANSMISSION...").font(.caption.bold())
                                    .foregroundColor(.cyan)
                            }
                            
                            // GUNAKAN 'messageText' DI SINI (jangan nama 'message' karena bisa bentrok)
                            Text(messageText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            // Tombol Acknowledge menggunakan onTapGesture
                            Text("ACKNOWLEDGE")
                                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .contentShape(Rectangle()) // Memastikan seluruh area bisa diklik
                                .onTapGesture {
                                    // Beri haptic feedback instan
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    
                                    // Tutup dialog tanpa animasi berlebihan yang bikin ngelag
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        controller.dismissDialogue()
                                    }
                                }
                                .padding(.top, 10)
                        }
                        .padding(24)
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan, lineWidth: 2))
                        .frame(width: 320)
                        .shadow(color: .cyan.opacity(0.3), radius: 20)
                    }
                    .zIndex(200) // Paling atas
                    .transition(.scale.combined(with: .opacity))
                }

            }
        }
    }
}

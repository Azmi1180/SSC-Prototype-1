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
                        // Tombol Keluar ke Menu
                        Button(action: { controller.exitToMenu() }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "cpu")
                            Text("RULES: \(controller.activeRules.count)/3")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.yellow)
                        .cornerRadius(4)
                        
                        Spacer()
                        
                        Text("SCORE: \(controller.score)")
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
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
            }
        }
    }
}

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
                
                // MARK: - LAYER 2.5: TOOLTIPS (Guidance)
                                
                // STEP 1: Tooltip di atas Client (User)
                if controller.scenario1.activeTooltip == .dragCableClientToRouter {
                    if let client = controller.currentLevel.clients.first {
                        TooltipView(text: "1. DRAG CABLE ➔ ROUTER", pointingUp: false)
                            .position(x: client.position.x * geo.size.width, y: (client.position.y * geo.size.height) - 50)
                            .id("tooltip_1")
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(50)
                    }
                }
                
                // STEP 2: Tooltip di atas Router (Minta tarik ke Server)
                if controller.scenario1.activeTooltip == .dragCableRouterToServer {
                    if let router = controller.currentLevel.routers.first {
                        TooltipView(text: "2. DRAG CABLE ➔ SERVER", pointingUp: false)
                            .position(x: router.position.x * geo.size.width, y: (router.position.y * geo.size.height) - 60)
                            .id("tooltip_2")
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(50)
                    }
                }
                
                // STEP 3: Tooltip di atas Router (Minta Config)
                if controller.scenario1.activeTooltip == .configureRouter {
                    if let router = controller.currentLevel.routers.first {
                        TooltipView(text: "3. TAP TO CONFIGURE", pointingUp: false)
                            .position(x: router.position.x * geo.size.width, y: (router.position.y * geo.size.height) - 60)
                            .id("tooltip_3")
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(50)
                    }
                }
                
                // LAYER 3: HUD (Score, Timer, Packet Loss, Legend)
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Button(action: { controller.exitToMenu() }) {
                                    Image(systemName: "stop.circle.fill").font(.title).foregroundColor(.red)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("DAY \(controller.scenario1.currentDay)")
                                        .fontWeight(.black).foregroundColor(.cyan)
                                    Text(String(format: "0:%02d", controller.scenario1.timeRemaining))
                                        .foregroundColor(.white)
                                }
                                .font(.system(.headline, design: .monospaced))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(6)
                            }
                            
                            // KOTAK PACKET LOSS BARU
                            HStack(spacing: 8) {
                                Text("PACKET LOSS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                // Indikator Titik-Titik Merah
                                HStack(spacing: 4) {
                                    ForEach(0..<controller.currentLevel.maxPacketLoss, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(index < controller.currentPacketLoss ? Color.red : Color.white.opacity(0.2))
                                            .frame(width: 12, height: 6)
                                            // Efek kedip kalau hilang banyak
                                            .shadow(color: index < controller.currentPacketLoss ? .red : .clear, radius: 4)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        // Kanan: Score Total
                        VStack(alignment: .trailing) {
                            Text("SCORE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(controller.score)")
                                .font(.system(.title2, design: .monospaced, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // --- BOTTOM HUD (Legend / Panduan Warna) ---
                    // Hanya muncul jika menu logic tidak terbuka
                    if !controller.showLogicMenu {
                        HStack(spacing: 20) {
                            LegendItem(color: Color(red: 1.0, green: 0.0, blue: 0.33), label: "VIDEO")
                            LegendItem(color: Color(red: 0.0, green: 1.0, blue: 0.8), label: "EMAIL")
                            LegendItem(color: Color(red: 0.22, green: 1.0, blue: 0.08), label: "MALWARE")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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


struct LegendItem: View {
    var color: Color
    var label: String
    
    var body: some View {
        HStack(spacing: 6) {
            // Gambar Diamond (Data Packet)
            ZStack {
                Rectangle()
                    .stroke(color.opacity(0.8), lineWidth: 1.5)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 4)
            }
            .rotationEffect(.degrees(45))
            .shadow(color: color, radius: 3)
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

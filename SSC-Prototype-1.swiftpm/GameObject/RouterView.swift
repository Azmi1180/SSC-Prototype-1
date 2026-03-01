//
//  RouterView.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 23/02/26.
//

import SwiftUI

struct RouterView: View {
    @ObservedObject var controller: GameController
    
    // ID Unik Router ini (dikirim dari ContentView)
    var routerID: UUID
    
    // State lokal untuk animasi visual (LED Breathing)
    @State private var pulseGlow: Bool = false
    
    // Warna Tema Router
    let matteBody = Color(red: 0.14, green: 0.14, blue: 0.15)
    let matteBase = Color(red: 0.08, green: 0.08, blue: 0.09)
    let ledPanel  = Color(red: 0.04, green: 0.04, blue: 0.05)
    let standbyCyan = Color.cyan
    let activeGreen = Color(red: 0.22, green: 1.0, blue: 0.08)
    
    var body: some View {
        VStack {
            ZStack {
                // MARK: - Shadow (Bayangan di lantai game)
                Ellipse()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 200, height: 15)
                    .offset(y: 40)
                    .blur(radius: 8)
                
                // MARK: - Antennas & Waves
                ZStack {
                    // Left Antenna
                    ZStack(alignment: .top) {
                        antennaPillar()
                        wifiWaves().offset(y: -10)
                    }
                    .rotationEffect(.degrees(-15), anchor: .bottom)
                    .offset(x: -90, y: -60)
                    
                    // Right Antenna
                    ZStack(alignment: .top) {
                        antennaPillar()
                        wifiWaves().offset(y: -10)
                    }
                    .rotationEffect(.degrees(15), anchor: .bottom)
                    .offset(x: 90, y: -60)
                }
                .zIndex(0)
                
                // MARK: - Router Body
                ZStack {
                    // 3D Base (Bagian bawah router)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(matteBase)
                        .frame(width: 280, height: 60)
                        .offset(y: 5)
                    
                    // Front Face (Bagian depan matte)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(matteBody)
                        .frame(width: 280, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Details (Ventilasi & LED Panel)
                    HStack(spacing: 0) {
                        // Left Vents
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule().fill(matteBase).frame(width: 4, height: 14)
                            }
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        // Central LED Panel
                        ZStack {
                            Capsule()
                                .fill(ledPanel)
                                .frame(width: 80, height: 16)
                                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 1))
                            
                            // Three Glowing LEDs
                            HStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        // Warna berubah jadi Hijau jika Menu Logic sedang dibuka
                                        .fill(controller.showLogicMenu ? activeGreen : standbyCyan)
                                        .frame(width: 5, height: 5)
                                        // Efek Glow Berdenyut
                                        .shadow(
                                            color: controller.showLogicMenu ? activeGreen : standbyCyan,
                                            radius: pulseGlow ? 6 : 2
                                        )
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Right Vents
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule().fill(matteBase).frame(width: 4, height: 14)
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    .frame(width: 280)
                }
                .zIndex(1)
            }
            // MARK: - Interaction (Tap Gesture)
            .onTapGesture {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    // Beritahu Controller router mana yang diklik
                    controller.selectRouter(id: routerID)
                    controller.scenario1.checkRouterClicked()
                }
            }
            
            // Status Text (Kecil di bawah router)
            Text(controller.showLogicMenu ? "CONFIG MODE" : "SYSTEM STANDBY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(controller.showLogicMenu ? activeGreen : standbyCyan)
                .opacity(0.7)
                .padding(.top, 45)
                .shadow(color: .black, radius: 2)
                .transition(.opacity)
        }
        .onAppear {
            // Mulai animasi denyut LED saat router muncul
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
    
    // MARK: - Subcomponents (Antenna & Waves)
    
    @ViewBuilder
    func antennaPillar() -> some View {
        Capsule()
            .fill(matteBase)
            .frame(width: 12, height: 140)
            .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    @ViewBuilder
    func wifiWaves() -> some View {
        ZStack {
            AnimatedWaveCircle(color: activeGreen, delay: 0.0)
            AnimatedWaveCircle(color: activeGreen, delay: 0.75)
        }
        // Gelombang sinyal HANYA muncul jika menu logic sedang dibuka (Visual feedback aktif)
        .opacity(controller.showLogicMenu ? 1.0 : 0.0)
        .clipShape(Rectangle().offset(y: -15))
    }
}

// MARK: - Wave Animation Component
struct AnimatedWaveCircle: View {
    let color: Color
    let delay: Double
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: 60, height: 60)
            .scaleEffect(isAnimating ? 1.0 : 0.01)
            .opacity(isAnimating ? 0.0 : 1.0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(delay)) {
                    isAnimating = true
                }
            }
    }
}

//
//  ServerRackView.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 23/02/26.
//

import SwiftUI

struct ServerRackView: View {
    @ObservedObject var controller: GameController
    var serverID: UUID
    var acceptedType: PacketType
    
    // Animation States
    @State private var isProcessing: Bool = false
    @State private var dataFlicker: Bool = false
    
    // Warna dasar chassis
    let darkChassis = Color(red: 0.1, green: 0.1, blue: 0.11)
    let ventColor = Color(red: 0.05, green: 0.05, blue: 0.06)
    
    var neonColor: Color {
        acceptedType.uiColor
    }
    
    var body: some View {
        ZStack {
            ZStack(alignment: .leading) {
                // Base Tower Shape
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(darkChassis)
                    .frame(width: 160, height: 380)
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1.5)
                    )
                
                HStack(spacing: 0) {
                    // Vertical Status Light Bar (Left side)
                    Capsule()
                        .fill(isProcessing ? neonColor : neonColor.opacity(0.2))
                        .frame(width: 4, height: 340)
                        .padding(.leading, 10)
                        // Native SwiftUI Glow Effect
                        .shadow(color: isProcessing ? neonColor.opacity(0.8) : .clear, radius: isProcessing ? 8 : 0)
                    
                    // Server Blades & Vents
                    VStack(spacing: 24) {
                        ForEach(0..<6, id: \.self) { index in
                            serverBlade(index: index)
                        }
                    }
                    .padding(.leading, 12)
                }
            }
            // Title Tag
            Text(acceptedType.name)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(neonColor)
                .offset(y: -210)
        }
        // Animasi ketika menerima paket dari SpriteKit
        .onReceive(controller.$serverAnimationTrigger) { triggerID in
            if triggerID == serverID {
                // Mainkan animasi saat paket masuk
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isProcessing = true
                }
                
                // Matikan kembali setelah 1 detik
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { isProcessing = false }
                }
            }
        }
        .onChange(of: isProcessing) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                    dataFlicker = true
                }
            } else {
                withAnimation { dataFlicker = false }
            }
        }
    }
    
    // MARK: - Subview for Individual Server Blades
    @ViewBuilder
    func serverBlade(index: Int) -> some View {
        HStack(spacing: 12) {
            // Horizontal Cooling Vents
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(ventColor)
                        .frame(width: 90, height: 6)
                        .overlay(Capsule().stroke(Color.black.opacity(0.8), lineWidth: 1))
                }
            }
            
            // Blade Status LEDs
            VStack(spacing: 8) {
                Circle()
                    .fill(isProcessing ? (dataFlicker ? neonColor : neonColor.opacity(0.3)) : neonColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .shadow(color: (isProcessing && dataFlicker) ? neonColor : .clear, radius: 4)
                
                if index == 2 {
                    let pink = Color(red: 1.0, green: 0.0, blue: 0.33)
                    Circle()
                        .fill(isProcessing ? (dataFlicker ? pink.opacity(0.3) : pink) : pink.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .shadow(color: (isProcessing && !dataFlicker) ? pink : .clear, radius: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

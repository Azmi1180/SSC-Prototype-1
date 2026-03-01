//
//  TooltipView.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 26/02/26.
//


import SwiftUI

struct TooltipView: View {
    var text: String
    var pointingUp: Bool = false // Panah menunjuk ke atas atau bawah
    
    @State private var bounce: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if pointingUp {
                Image(systemName: "triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
                    .padding(.bottom, -4)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.yellow)
                .cornerRadius(8)
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            
            if !pointingUp {
                Image(systemName: "triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(180))
                    .padding(.top, -4)
            }
        }
        .offset(y: bounce ? -5 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}
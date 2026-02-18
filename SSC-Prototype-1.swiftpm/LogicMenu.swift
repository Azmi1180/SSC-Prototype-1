//
//  LogicMenu.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

struct LogicMenu: View {
    @ObservedObject var controller: GameController
    
    var body: some View {
        VStack(spacing: 20) {
            Text("CONFIGURE ROUTER")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)
                .padding(.top)
            
            Divider().background(Color.white)
            
            ForEach(RouterLogic.allCases, id: \.self) { logic in
                Button(action: {
                    controller.updateLogic(logic)
                    controller.showLogicMenu = false
                }) {
                    HStack {
                        Text(logic.rawValue)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                        Spacer()
                        if controller.selectedRouterLogic == logic {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
                .foregroundColor(logic == .sortColor ? Theme.accent : .white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15).edgesIgnoringSafeArea(.all))
    }
}

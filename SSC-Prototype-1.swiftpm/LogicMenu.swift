//
//  LogicMenu.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

struct LogicMenu: View {
    @ObservedObject var controller: GameController
    
    // Builders
    @State private var selectedColor: PacketType = .video
    @State private var selectedAction: RouterAction = .sendTop
    
    var body: some View {
        ZStack {
            // Darkens the game background behind the menu
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Main Window Card
            VStack(spacing: 0) {
                
                // MARK: - Header
                HStack {
                    Image(systemName: "cpu.fill")
                        .foregroundColor(.white)
                    
                    Text("ROUTER_CONFIG")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { controller.showLogicMenu = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(white: 0.15)) // Lighter header background
                
                Divider().background(Color.white.opacity(0.2))
                
                // MARK: - Memory / Active Rules List
                List {
                    if controller.activeRules.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("> MEMORY EMPTY")
                            Text("> PACKETS ROUTING RANDOMLY...")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6)) // High contrast empty text
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                    }
                    
                    ForEach(controller.activeRules) { rule in
                        HStack(spacing: 12) {
                            Text("IF")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            // Color Badge
                            Text(rule.conditionColor.name)
                                .font(.system(.caption, design: .monospaced, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(rule.conditionColor.uiColor.opacity(0.2))
                                .foregroundColor(rule.conditionColor.uiColor)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(rule.conditionColor.uiColor.opacity(0.5), lineWidth: 1)
                                )
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            
                            // Action Badge
                            Text(rule.action.rawValue)
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        // Clean up standard List styling
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                    .onDelete(perform: controller.removeRule)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160, maxHeight: 220)
                .background(Color(white: 0.1)) // Darker background for the list area
                
                // MARK: - Compiler Panel (Add Rule)
                VStack(spacing: 24) {
                    
                    // Section Title
                    HStack {
                        Image(systemName: "plus.diamond.fill")
                            .foregroundColor(Theme.accent) // Uses your yellow
                        Text("NEW INSTRUCTION")
                            .font(.system(.subheadline, design: .monospaced, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    // Picker Columns
                    HStack(spacing: 16) {
                        // "IF" Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IF PACKET IS:")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7)) // High contrast label
                            
                            Picker("", selection: $selectedColor) {
                                Text("RED").tag(PacketType.video)
                                Text("BLUE").tag(PacketType.email)
                                Text("GREEN").tag(PacketType.malware)
                            }
                            .pickerStyle(.menu)
                            .tint(.white) // Forces arrow to be white
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15)) // Highly visible box
                            .cornerRadius(8)
                        }
                        
                        // "THEN" Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("THEN DO:")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7)) // High contrast label
                            
                            Picker("", selection: $selectedAction) {
                                Text("SEND TOP").tag(RouterAction.sendTop)
                                Text("SEND BTM").tag(RouterAction.sendBottom)
                                Text("DROP").tag(RouterAction.drop)
                            }
                            .pickerStyle(.menu)
                            .tint(.white) // Forces arrow to be white
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15)) // Highly visible box
                            .cornerRadius(8)
                        }
                    }
                    
                    // Compile Button
                    VStack(spacing: 8) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            controller.addRule(color: selectedColor, action: selectedAction)
                        }) {
                            Text(controller.activeRules.count >= 3 ? "SYSTEM LOCKED" : "COMPILE CODE [+]")
                                .font(.system(.headline, design: .monospaced, weight: .black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(controller.activeRules.count < 3 ? Theme.accent : Color.white.opacity(0.2))
                                .foregroundColor(controller.activeRules.count < 3 ? .black : .white.opacity(0.5))
                                .cornerRadius(10)
                                .shadow(color: controller.activeRules.count < 3 ? Theme.accent.opacity(0.4) : .clear, radius: 8, y: 4)
                        }
                        .disabled(controller.activeRules.count >= 3)
                        
                        // Error Output Placeholder (keeps layout stable)
                        Text(controller.activeRules.count >= 3 ? "[ ERROR: MEMORY BANK FULL ]" : " ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                .padding(24)
                .background(Color(white: 0.15)) // Matches the header
            }
            .frame(minWidth: 360) // Clean card width
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.8), radius: 30, x: 0, y: 15)
            .environment(\.colorScheme, .dark)
        }
    }
}

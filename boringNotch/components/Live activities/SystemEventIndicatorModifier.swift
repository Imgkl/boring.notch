    //
    //  SystemEventIndicatorModifier.swift
    //  boringNotch
    //
    //  Created by Richard Kunkli on 12/08/2024.
    //

import SwiftUI

struct SystemEventIndicatorModifier: View {
    @EnvironmentObject var vm: BoringViewModel
    @State var eventType: SystemEventType
    @Binding var value: CGFloat
    let showSlider: Bool = false
    var sendEventBack: () -> Void = {}
    
    var body: some View {
            HStack(spacing: 14) {
                switch (eventType) {
                    case .volume:
                        Image(systemName: SpeakerSymbol(value))
                            .contentTransition(.interpolate)
                            .frame(width: 20, height: 15, alignment: .leading)
                    case .brightness:
                        Image(systemName: "sun.max.fill")
                            .contentTransition(.interpolate)
                            .frame(width: 20, height: 15)
                    case .backlight:
                        Image(systemName: "keyboard")
                            .contentTransition(.interpolate)
                            .frame(width: 20, height: 15)
                    case .mic:
                        Image(systemName: "mic")
                            .symbolVariant(value > 0 ? .none : .slash)
                            .contentTransition(.interpolate)
                            .frame(width: 20, height: 15)
                }
                if (eventType != .mic) {
                    DraggableProgressBar(value: $value)
                } else {
                    Text("Mic \(value > 0 ? "unmuted" : "muted")")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .symbolVariant(.fill)
            .imageScale(.large)
    }
    
    func SpeakerSymbol(_ value: CGFloat) -> String {
        switch(value) {
            case 0:
                return "speaker.slash"
            case 0...0.3:
                return "speaker.wave.1"
            case 0.3...0.8:
                return "speaker.wave.2"
            case 0.8...1:
                return "speaker.wave.3"
            default:
                return "speaker.wave.2"
        }
    }
}

enum SystemEventType {
    case volume
    case brightness
    case backlight
    case mic
}

#Preview {
    VStack(spacing: 20) {
        SystemEventIndicatorModifier(eventType: .volume, value: .constant(0.4), sendEventBack: {
            print("Volume changed")
        })
        SystemEventIndicatorModifier(eventType: .brightness, value: .constant(0.7),sendEventBack: {
            print("Volume changed")
        })
        SystemEventIndicatorModifier(eventType: .backlight, value: .constant(0.2), sendEventBack: {
            print("Volume changed")
        })
        SystemEventIndicatorModifier(eventType: .mic, value: .constant(0.2), sendEventBack: {
            print("Volume changed")
        })
    }
    .frame(width: 200)
    .padding()
    .background(.black)
    .environmentObject(BoringViewModel())
}

struct DraggableProgressBar: View {
    @EnvironmentObject var vm: BoringViewModel
    @Binding var value: CGFloat
    
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(LinearGradient(colors: vm.systemEventIndicatorUseAccent ? [vm.accentColor, vm.accentColor.ensureMinimumBrightness(factor: 0.2)] : [.white, .white.opacity(0.2)], startPoint: .trailing, endPoint: .leading))
                        .frame(width: max(0, min(geo.size.width * value, geo.size.width)))
                        .shadow(color: vm.systemEventIndicatorShadow ? vm.systemEventIndicatorUseAccent ? vm.accentColor.ensureMinimumBrightness(factor: 0.7) : .white : .clear, radius: 8, x: 3)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            withAnimation(.smooth(duration: 0.3)) {
                                isDragging = true
                                updateValue(gesture: gesture, in: geo)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.smooth(duration: 0.3)) {
                                isDragging = false
                            }
                        }
                )
            }
            .frame(height: isDragging ? 9 : 6)
        }
    }
    
    private func updateValue(gesture: DragGesture.Value, in geometry: GeometryProxy) {
        let dragPosition = gesture.location.x
        let newValue = dragPosition / geometry.size.width
        
        value = max(0, min(newValue, 1))
    }
}

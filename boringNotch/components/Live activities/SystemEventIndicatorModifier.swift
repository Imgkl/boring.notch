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
        VStack {
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
                        Image(systemName: MicSymbol(value))
                            .contentTransition(.interpolate)
                            .frame(width: 20, height: 15)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                        Capsule()
                            .fill(LinearGradient(colors: vm.systemEventIndicatorUseAccent ? [vm.accentColor, vm.accentColor.ensureMinimumBrightness(factor: 0.2)] : [.white, .white.opacity(0.2)], startPoint: .trailing, endPoint: .leading))
                            .frame(width: geo.size.width * value)
                            .shadow(color: vm.systemEventIndicatorShadow ? vm.systemEventIndicatorUseAccent ? vm.accentColor.ensureMinimumBrightness(factor: 0.7) : .white : .clear, radius: 8, x: 3)
                    }
                }
                .frame(height: 6)
            }
            .symbolVariant(.fill)
            .imageScale(.large)
            if showSlider {
                Slider(value: $value.animation(.smooth), in: 0...1, onEditingChanged: {
                    _ in sendEventBack()
                })
            }
        }
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
    
    func MicSymbol(_ value: CGFloat) -> String {
        return value > 0 ? "mic" : "mic.slash"
    }
}

enum SystemEventType {
    case volume
    case brightness
    case backlight
    case mic
}

#Preview {
    VStack{
        SystemEventIndicatorModifier(eventType: .volume, value: .constant(0.4), sendEventBack: {
            print("Volume changed")
        })
        SystemEventIndicatorModifier(eventType: .brightness, value: .constant(0.7),sendEventBack: {
            print("Volume changed")
        })
        SystemEventIndicatorModifier(eventType: .backlight, value: .constant(0.2), sendEventBack: {
            print("Volume changed")
        })
    }
    .frame(width: 200)
    .padding()
    .background(.black)
}

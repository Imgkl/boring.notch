    //
    //  NotchContentView.swift
    //  boringNotch
    //
    //  Created by Richard Kunkli on 13/08/2024.
    //

import SwiftUI

struct NotchContentView: View {
    @EnvironmentObject var vm: BoringViewModel
    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject var batteryModel: BatteryStatusViewModel
    @EnvironmentObject var volumeChangeListener: VolumeChangeListener
    var clipboardManager: ClipboardManager?
    @StateObject var microphoneHandler: MicrophoneHandler
    
    var body: some View {
        VStack {
            if vm.notchState == .open {
                VStack(spacing: 10) {
                    BoringHeader(vm: vm, percentage: batteryModel.batteryPercentage, isCharging: batteryModel.isPluggedIn).padding(.leading, 6).padding(.trailing, 6).animation(.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0.8), value: vm.notchState)
                    if vm.firstLaunch {
                        HelloAnimation().frame(width: 180, height: 60).onAppear(perform: {
                            vm.closeHello()
                        })
                    }
                }
            }
            
            if !vm.firstLaunch {
                
                HStack(spacing: 15) {
                    if vm.notchState == .closed && vm.expandingView.show {
                        Text(vm.expandingView.type == .battery ? "Charging" : "Downloading").foregroundStyle(.white).padding(.leading, 4)
                    }
                    if !vm.expandingView.show && vm.currentView != .menu  {
                        
                        Image(nsImage: musicManager.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: vm.notchState == .open ? vm.musicPlayerSizes.image.size.opened.width : vm.musicPlayerSizes.image.size.closed.width,
                                height: vm.notchState == .open ? vm.musicPlayerSizes.image.size.opened.height : vm.musicPlayerSizes.image.size.closed.height
                            )
                            .cornerRadius(vm.notchState == .open ? vm.musicPlayerSizes.image.cornerRadius.opened.inset! : vm.musicPlayerSizes.image.cornerRadius.closed.inset!)
                            .scaledToFit()
                            .padding(.leading, vm.notchState == .open ? 5 : 3)
                    }
                    
                    if vm.notchState == .open {
                        if vm.currentView == .menu {
                            BoringExtrasMenu(vm: vm).transition(.blurReplace.animation(.spring(.bouncy(duration: 0.3))))
                        }
                        
                        if vm.currentView != .menu {
                            if true {
                                VStack(alignment: .leading, spacing: 5) {
                                    VStack(alignment: .leading, spacing: 3){
                                        Text(musicManager.songTitle)
                                            .font(.headline)
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(musicManager.artistName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    HStack(spacing: 5) {
                                        Button {
                                            musicManager.previousTrack()
                                        } label: {
                                            Rectangle()
                                                .fill(.clear)
                                                .contentShape(Rectangle())
                                                .frame(width: 30, height: 30)
                                                .overlay {
                                                    Image(systemName: "backward.fill")
                                                        .foregroundColor(.white)
                                                        .imageScale(.medium)
                                                }
                                        }
                                        Button {
                                            print("tapped")
                                            musicManager.togglePlayPause()
                                        } label: {
                                            Rectangle()
                                                .fill(.clear)
                                                .contentShape(Rectangle())
                                                .frame(width: 30, height: 30)
                                                .overlay {
                                                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                                        .foregroundColor(.white)
                                                        .contentTransition(.symbolEffect)
                                                        .imageScale(.large)
                                                }
                                        }
                                        Button {
                                            musicManager.nextTrack()
                                        } label: {
                                            Rectangle()
                                                .fill(.clear)
                                                .contentShape(Rectangle())
                                                .frame(width: 30, height: 30)
                                                .overlay {
                                                    Capsule()
                                                        .fill(.black)
                                                        .frame(width: 30, height: 30)
                                                        .overlay {
                                                            Image(systemName: "forward.fill")
                                                                .foregroundColor(.white)
                                                                .imageScale(.medium)
                                                            
                                                        }
                                                }
                                        }
                                    }
                                }
                                .allowsHitTesting(!vm.notchMetastability)
                                .transition(.blurReplace.animation(.spring(.bouncy(duration: 0.3)).delay(vm.notchState == .closed ? 0 : 0.1)))
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    
                    if vm.currentView != .menu {
                        Spacer()
                    }
                    
                    if musicManager.isPlayerIdle == true && vm.notchState == .closed && !vm.expandingView.show && vm.nothumanface {
                        MinimalFaceFeatures().transition(.blurReplace.animation(.spring(.bouncy(duration: 0.3))))
                    }
                    
                    
                    if vm.currentView != .menu && vm.notchState == .closed && vm.expandingView.show  {
                        if vm.expandingView.type == .battery {
                            BoringBatteryView(batteryPercentage: batteryModel.batteryPercentage, isPluggedIn: batteryModel.isPluggedIn, batteryWidth: 30)
                        } else {
                            HStack (spacing: 10){
                                ProgressIndicator(type: .text, progress: 0.12, color: vm.accentColor)
                                ProgressIndicator(type: .circle, progress: 0.12, color: vm.accentColor)
                                
                            }
                        }
                        
                    }
                    
                    if vm.notchState == .closed && !vm.expandingView.show && (musicManager.isPlaying || !musicManager.isPlayerIdle) {
                        MusicVisualizer(avgColor: musicManager.avgColor, isPlaying: musicManager.isPlaying)
                            .frame(width: 30)
                    }
                    
                    if vm.notchState == .open {
                        
                        BoringSystemTiles(vm: vm, microphoneHandler:microphoneHandler).transition(.blurReplace.animation(.spring(.bouncy(duration: 0.3)).delay(0.1)))
                        
                    }
                }
            }
            
            if ((vm.notchState == .closed &&  vm.sneakPeak.show ) && (!vm.expandingView.show)) {
                switch vm.sneakPeak.type {
                    case .music:
                        HStack() {
                            Image(systemName: "music.note").padding(.leading, 4)
                            Text(musicManager.songTitle)
                                .font(.headline)
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            Spacer()
                        }
                        .foregroundStyle(.gray, .gray).transition(.blurReplace.animation(.spring(.bouncy(duration: 0.3)).delay(0.1))).padding(2)
                    case .volume:
                        SystemEventIndicatorModifier(eventType: .volume, value: $vm.sneakPeak.value, sendEventBack: {
                            print("Volume changed")
                        })
                        .transition(.opacity.combined(with: .blurReplace))
                        .padding([.leading, .top], musicManager.isPlaying ? 4 : 0)
                        .padding(.trailing, musicManager.isPlaying ? 8 : 4)
                    case .brightness:
                        SystemEventIndicatorModifier(eventType: .brightness, value: $vm.sneakPeak.value, sendEventBack: {
                            print("Volume changed")
                        })
                        .transition(.opacity.combined(with: .blurReplace))
                        .padding([.leading, .top], musicManager.isPlaying ? 4 : 0)
                        .padding(.trailing, musicManager.isPlaying ? 8 : 4)
                    case .backlight:
                        SystemEventIndicatorModifier(eventType: .backlight, value: $vm.sneakPeak.value, sendEventBack: {
                            print("Volume changed")
                        })
                        .transition(.opacity.combined(with: .blurReplace))
                        .padding([.leading, .top], musicManager.isPlaying ? 4 : 0)
                        .padding(.trailing, musicManager.isPlaying ? 8 : 4)
                    case .mic:
                        SystemEventIndicatorModifier(eventType: .mic, value: $vm.sneakPeak.value, sendEventBack: {
                            print("Volume changed")
                        }).transition(.opacity.combined(with: .blurReplace))
                            .padding([.leading, .top], musicManager.isPlaying ? 4 : 0)
                            .padding(.trailing, musicManager.isPlaying ? 8 : 4)
                    default:
                        EmptyView()
                }
            }
            
           // if vm.notchState == .open {
                // DownloadArea().padding(.vertical, 10).padding(.horizontal, 4).transition(.blurReplace.animation(.spring(.bouncy(duration: 0.5))))
           // }
        }
        .frame(width: calculateFrameWidthforNotchContent())
        .transition(.blurReplace.animation(.spring(.bouncy(duration: 0.5))))
    }
    
    func calculateFrameWidthforNotchContent() -> CGFloat? {
            // Calculate intermediate values
        let chargingInfoWidth: CGFloat = vm.expandingView.show ? 160 : 0
        let musicPlayingWidth: CGFloat = (!vm.firstLaunch && !vm.expandingView.show && (musicManager.isPlaying || (musicManager.isPlayerIdle ? vm.nothumanface : true))) ? 60 : -15
        
        let closedWidth: CGFloat = vm.sizes.size.closed.width! - 10
        
        let dynamicWidth: CGFloat = chargingInfoWidth + musicPlayingWidth + closedWidth
            // Return the appropriate width based on the notch state
        return vm.notchState == .open ? vm.musicPlayerSizes.player.size.opened.width : dynamicWidth + (vm.sneakPeak.show ? -12 : 0)
    }
}

#Preview {
    BoringNotch(vm: BoringViewModel(), batteryModel: BatteryStatusViewModel(vm: .init()), onHover: onHover, clipboardManager: ClipboardManager(vm: .init()), microphoneHandler: MicrophoneHandler(vm:.init())).frame(width: 600)
}

    //
    //  BoringViewModel.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 04/08/24.
    //

import SwiftUI
import Combine

enum SneakContentType {
    case brightness
    case volume
    case backlight
    case music
    case mic
}

struct SneakPeak {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
}

class BoringViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    
    let animationLibrary: BoringAnimations = BoringAnimations()
    let animation: Animation?
    @Published var contentType: ContentType = .normal
    @Published var notchState: NotchState = .closed
    @Published var currentView: NotchViews = .empty
    @Published var headerTitle: String = "Boring Notch"
    @Published var emptyStateText: String = "Play some jams, ladies, and watch me shine! New features coming soon! 🎶 🚀"
    @Published var sizes : Sizes = Sizes()
    @Published var musicPlayerSizes: MusicPlayerElementSizes = MusicPlayerElementSizes()
    @Published var waitInterval: Double = 3
    @Published var releaseName: String = "Sleeping Snail 🐌"
    @Published var coloredSpectrogram: Bool = true
    @Published var accentColor: Color = .accentColor
    @Published var selectedDownloadIndicatorStyle: DownloadIndicatorStyle = .progress
    @Published var selectedDownloadIconStyle: DownloadIconStyle = .onlyAppIcon
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    @Published var enableHaptics: Bool = true
    @Published var nothumanface: Bool = false
    @Published var showBattery: Bool = true
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @Published var showChargingInfo: Bool = true
    @Published var chargingInfoAllowed: Bool = true
    @AppStorage("showWhatsNew") var showWhatsNew: Bool = true
    @Published var whatsNewOnClose: (() -> Void)?
    @Published var minimumHoverDuration: TimeInterval = 0.3
    @Published var notchMetastability: Bool = true // True if notch not open
    @Published var settingsIconInNotch: Bool = true
    private var sneakPeakDispatch: DispatchWorkItem?
    @Published var enableSneakPeek: Bool = false
    @Published var showCHPanel: Bool = false
    @Published var sneakPeak: SneakPeak = SneakPeak() {
        didSet {
            if sneakPeak.show {
                sneakPeakDispatch?.cancel()
                
                sneakPeakDispatch = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    withAnimation {
                        self.toggleSneakPeak(status: false, type: SneakContentType.music)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: sneakPeakDispatch!)
            }
        }
    }
    @Published var maxClipboardRecords: Int = 1000;
    
    deinit {
        destroy()
    }
    
    func destroy() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    override
    init() {
        self.animation = self.animationLibrary.animation
        super.init()
        print("BoringViewModel initialized")
    }
    
    func open(){
        self.notchState = .open
    }
    
    func toggleSneakPeak(status:Bool, type: SneakContentType, value: CGFloat = 0 ) {
        if self.sneakPeak.show {
            withAnimation {
                self.sneakPeak.show = false;
            }
        }
        DispatchQueue.main.async {
            withAnimation{
                self.sneakPeak.show = status
                self.sneakPeak.type = type
                self.sneakPeak.value = value
            }
        }
    }
    
    func close(){
        self.notchState = .closed
    }
    
    func openMenu(){
        self.currentView = .menu
    }
    
    func openMusic(){
        self.currentView = .music
    }
    
    func openClipboard() {
        self.showCHPanel = true;
    }
    
    func showEmpty() {
        self.currentView = .empty
    }
    
    func closeHello() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2){
            self.firstLaunch = false;
            withAnimation(self.animationLibrary.animation){
                self.close()
            }
        }
    }
}


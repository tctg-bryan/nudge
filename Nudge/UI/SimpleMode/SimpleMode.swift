//
//  SimpleMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// SimpleMode
struct SimpleMode: View {
    @ObservedObject var viewObserved: ViewState
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    // State variables
    @State var allowButtons = true
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    @State var hasClickedCustomDeferralButton = false
    @State var hasClickedSecondaryQuitButton = false
    @State var nudgeEventDate = Date()
    @State var nudgeCustomEventDate = Date()
    
    // Modal view for screenshot and deferral info
    @State var showDeviceInfo = false
    @State var showDeferView = false

    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let companyLogoPath = Utils().getCompanyLogoPath(darkMode: darkMode)
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Button(action: {
                        Utils().userInitiatedDeviceInfo()
                        self.showDeviceInfo.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .padding(.leading, -2.0)
                    .padding(.top, -3.0)
                    .buttonStyle(.plain)
                    .help("Click for additional device information".localized(desiredLanguage: getDesiredLanguage()))
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .sheet(isPresented: $showDeviceInfo) {
                        DeviceInfo()
                    }
                    Spacer()
                }
            }
            .frame(width: 894, height: 20)

            VStack(alignment: .center, spacing: 10) {
                // Company Logo
                HStack {
                    if FileManager.default.fileExists(atPath: companyLogoPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: companyLogoPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                    }
                }
                .frame(width: 300, height: 225)

                // mainHeader
                HStack {
                    Text(getMainHeader())
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Days Remaining
                HStack(spacing: 3.5) {
                    Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                        .font(.title2)
                    if self.daysRemaining <= 0 {
                        Text(String(self.daysRemaining))
                            .foregroundColor(.red)
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text(String(self.daysRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                // Deferral Count
                if showDeferralCount {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                            .font(.title2)
                        Text(String(viewObserved.userDeferralCount))
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                } else {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                            .font(.title2)
                        Text(String(viewObserved.userDeferralCount))
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .hidden()
                }
                Spacer()

                // actionButton
                Button(action: {
                    Utils().updateDevice()
                }) {
                    Text(actionButtonText)
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
            
            // Bottom buttons
            HStack {
                // informationButton
                if aboutUpdateURL != "" {
                    Button(action: Utils().openMoreInfo, label: {
                        Text(informationButtonText)
                            .foregroundColor(.secondary)
                    }
                    )
                        .buttonStyle(.plain)
                        .help("Click for more information about the security update".localized(desiredLanguage: getDesiredLanguage()))
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    
                }

                // Separate the buttons with a spacer
                Spacer()

                if allowButtons || Utils().demoModeEnabled() {
                    // secondaryQuitButton
                    if viewObserved.requireDualQuitButtons {
                        HStack(spacing: 20) {
                            if self.hasClickedSecondaryQuitButton == false {
                                Button {
                                    hasClickedSecondaryQuitButton = true
                                    userHasClickedSecondaryQuitButton()
                                } label: {
                                    Text(secondaryQuitButtonText)
                                }
                                .padding(.leading, -200.0)
                            }
                        }
                        .frame(maxHeight: 30)
                    }
                    
                    // primaryQuitButton
                    if viewObserved.requireDualQuitButtons == false || hasClickedSecondaryQuitButton {
                        HStack(spacing: 20) {
                            if allowUserQuitDeferrals {
                                Menu("Defer".localized(desiredLanguage: getDesiredLanguage())) {
                                    Button {
                                        Utils().logUserQuitDeferrals()
                                        nudgeDefaults.set(nudgeEventDate, forKey: "deferRunUntil")
                                        Utils().userInitiatedExit()
                                    } label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                    }
                                    if Utils().allow1HourDeferral() {
                                        Button {
                                            Utils().logUserQuitDeferrals()
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(3600), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(3600))
                                            Utils().userInitiatedExit()
                                        } label: {
                                            Text(oneHourDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allow24HourDeferral() {
                                        Button {
                                            Utils().logUserQuitDeferrals()
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(86400), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(86400))
                                            Utils().userInitiatedExit()
                                        } label: {
                                            Text(oneDayDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allowCustomDeferral() {
                                        Divider()
                                        Button {
                                            self.showDeferView.toggle()
                                        } label: {
                                            Text(customDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                }
                                .frame(maxWidth: 100)
                            } else {
                                Button {
                                    Utils().logUserQuitDeferrals()
                                    Utils().userInitiatedExit()
                                } label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: 35)
                                }
                            }
                        }
                        .frame(maxHeight: 30)
                        .sheet(isPresented: $showDeferView) {
                            if viewObserved.shouldExit {
                                Utils().userInitiatedExit()
                            }
                        } content: {
                            DeferView(viewObserved: viewObserved)
                        }
                    }
                }
            }
            .frame(width: 860)
            .padding(.bottom, -17.5)
        }
        .frame(width: 900, height: 450)
        .onAppear() {
            updateUI()
        }
        .onReceive(nudgeRefreshCycleTimer) { _ in
            if needToActivateNudge(lastRefreshTimeVar: lastRefreshTime) {
                viewObserved.userDeferralCount += 1
            }
            updateUI()
        }
    }
    
    var limitRange: ClosedRange<Date> {
        let daysRemaining = Utils().getNumberOfDaysBetween()
        if daysRemaining > 0 {
            // Do not let the user defer past the point of the approachingWindowTime
            return Date()...Calendar.current.date(byAdding: .day, value: daysRemaining-(imminentWindowTime / 24), to: Date())!
        } else {
            return Date()...Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        }
    }

    func updateUI() {
        if Utils().requireDualQuitButtons() || viewObserved.userDeferralCount > allowedDeferralsUntilForcedSecondaryQuitButton {
            viewObserved.requireDualQuitButtons = true
        }
        if Utils().pastRequiredInstallationDate() || hasLoggedDeferralCountPastThreshold {
            self.allowButtons = false
        }
        self.daysRemaining = Utils().getNumberOfDaysBetween()
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct SimpleModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                SimpleMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                SimpleMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif

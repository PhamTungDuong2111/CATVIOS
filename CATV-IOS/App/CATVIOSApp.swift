import SwiftUI

@main
struct CATVIOSApp: App {
    var body: some Scene {
        WindowGroup {
            MainCameraView()
                .preferredColorScheme(.dark)
        }
    }
}

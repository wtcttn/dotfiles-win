import AppKit
import CoreLocation
import CoreWLAN
import Foundation

final class Locator: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    let wait: Bool
    private var finished = false

    init(wait: Bool) {
        self.wait = wait
        super.init()
    }

    func start() {
        manager.delegate = self
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            if !wait {
                fputs("prompt\n", stderr)
                exit(5)
            }
            return
        }
        handle(status)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handle(manager.authorizationStatus)
    }

    func handle(_ status: CLAuthorizationStatus) {
        if finished { return }
        switch status {
        case .authorized, .authorizedAlways:
            finished = true
            emit()
        case .denied, .restricted:
            finished = true
            fputs("denied\n", stderr)
            exit(2)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func emit() {
        let ssid = CWWiFiClient.shared().interface()?.ssid() ?? ""
        if ssid.isEmpty || ssid == "<redacted>" {
            fputs("redacted\n", stderr)
            exit(3)
        }
        print(ssid)
        exit(0)
    }
}

let wait = CommandLine.arguments.contains("--wait")
let locator = Locator(wait: wait)
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
locator.start()
if wait {
    RunLoop.main.run(until: Date().addingTimeInterval(40))
    fputs("timeout\n", stderr)
    exit(4)
}

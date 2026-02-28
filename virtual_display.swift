import Foundation
import CoreGraphics
import IOKit

// Reverse engineered CoreDisplay functions
@_silgen_name("CGVirtualDisplayCreate")
func CGVirtualDisplayCreate(_ descriptor: Unmanaged<CFDictionary>?) -> UInt32

@_silgen_name("CGVirtualDisplayApplySettings")
func CGVirtualDisplayApplySettings(_ display: UInt32, _ settings: Unmanaged<CFDictionary>?) -> Int32

func createVirtualDisplay() -> UInt32 {
    let width = 1920
    let height = 1080
    let hiDPI = true
    
    // Use an existing known product ID so it registers as a monitor
    let descriptor: [String: Any] = [
        "hiDPI": hiDPI,
        "name": "MacDisplay Virtual Screen",
        "vendorID": 0xA5A5,
        "productID": 0xA5A5,
        "serialNum": 0x0
    ]
    
    let display = CGVirtualDisplayCreate(Unmanaged.passRetained(descriptor as CFDictionary))
    
    guard display != 0 else {
        print("Failed to create virtual display")
        return 0
    }
    
    print("Virtual display created with ID: \(display)")
    
    let settings: [String: Any] = [
        "resolution": [width, height],
        "refreshRate": 60.0
    ]
    
    let result = CGVirtualDisplayApplySettings(display, Unmanaged.passRetained(settings as CFDictionary))
    
    if result == 0 {
        print("Settings applied successfully.")
    } else {
        print("Failed to apply settings: error \(result)")
    }
    
    return display
}

let displayId = createVirtualDisplay()
if displayId != 0 {
    print("Virtual display is active. Press Enter to destroy the virtual display and exit.")
    _ = readLine()
} else {
    print("Failed")
}

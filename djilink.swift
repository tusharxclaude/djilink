// Maps the DJI Mic Mini 2 receiver's Link button (HID Volume Up) to a keystroke.
// Usage: djilink [--keycode 49] [--flags option] [--product 0x4011] [--no-seize] [--list]
import Foundation
import IOKit.hid
import CoreGraphics

let vendorID = 0x2ca3
var productID = 0x4011
let volumeUpPage: UInt32 = 0x0C
let volumeUpUsage: UInt32 = 0xE9

var keyCode: CGKeyCode = 49  // space
var flags: CGEventFlags = .maskAlternate  // option
var seize = true

var args = CommandLine.arguments.dropFirst().makeIterator()
while let a = args.next() {
    switch a {
    case "--keycode": keyCode = CGKeyCode(args.next().flatMap { UInt16($0) } ?? 49)
    case "--flags":
        flags = []
        for f in (args.next() ?? "").split(separator: ",") {
            switch f {
            case "option": flags.insert(.maskAlternate)
            case "command": flags.insert(.maskCommand)
            case "control": flags.insert(.maskControl)
            case "shift": flags.insert(.maskShift)
            default: break
            }
        }
    case "--no-seize": seize = false
    case "--product":
        let s = args.next() ?? ""
        productID = Int(s.hasPrefix("0x") ? String(s.dropFirst(2)) : s, radix: s.hasPrefix("0x") ? 16 : 10) ?? productID
    case "--list":
        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(m, [kIOHIDVendorIDKey: vendorID] as CFDictionary)
        IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone))
        let devices = (IOHIDManagerCopyDevices(m) as? Set<IOHIDDevice>) ?? []
        if devices.isEmpty { print("No DJI (vendor 0x2ca3) HID devices found.") }
        for d in devices {
            let name = IOHIDDeviceGetProperty(d, kIOHIDProductKey as CFString) as? String ?? "?"
            let pid = IOHIDDeviceGetProperty(d, kIOHIDProductIDKey as CFString) as? Int ?? 0
            print(String(format: "%@  product=0x%04x", name, pid))
        }
        exit(0)
    default: break
    }
}

func postKey() {
    let src = CGEventSource(stateID: .hidSystemState)
    for down in [true, false] {
        let e = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: down)
        e?.flags = flags
        e?.post(tap: .cghidEventTap)
    }
}

let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(mgr, [kIOHIDVendorIDKey: vendorID, kIOHIDProductIDKey: productID] as CFDictionary)

let valueCb: IOHIDValueCallback = { _, _, _, value in
    let el = IOHIDValueGetElement(value)
    guard IOHIDElementGetUsagePage(el) == volumeUpPage,
          IOHIDElementGetUsage(el) == volumeUpUsage,
          IOHIDValueGetIntegerValue(value) == 1 else { return }
    postKey()
}
IOHIDManagerRegisterInputValueCallback(mgr, valueCb, nil)
IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let opts = seize ? IOOptionBits(kIOHIDOptionsTypeSeizeDevice) : IOOptionBits(kIOHIDOptionsTypeNone)
let r = IOHIDManagerOpen(mgr, opts)
FileHandle.standardError.write("djilink: open result \(r) (seize=\(seize))\n".data(using: .utf8)!)
if r != kIOReturnSuccess { exit(1) }
CFRunLoopRun()

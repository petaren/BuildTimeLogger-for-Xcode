//
//  MACAddressManager.swift
//  BuildTimeLogger
//
//  Created by Petar Mataic on 2018-07-23.
//  Copyright © 2018 Marcin Religa. All rights reserved.
//

import Foundation
// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.

class MACAddressManager {
    static var MACAddress: String? {
        guard let intfIterator = FindEthernetInterfaces() else { return nil }

        defer {
            IOObjectRelease(intfIterator)
        }

        guard let macAddress = GetMACAddress(intfIterator: intfIterator) else { return nil }

        let macAddressAsString = macAddress.map( { String(format:"%02x", $0) } ).joined(separator: ":")
        return macAddressAsString
    }

    private static func FindEthernetInterfaces() -> io_iterator_t? {

        let matchingDictUM = IOServiceMatching("IOEthernetInterface")
        // Note that another option here would be:
        // matchingDict = IOBSDMatching("en0");
        // but en0: isn't necessarily the primary interface, especially on systems with multiple Ethernet ports.

        if matchingDictUM == nil {
            return nil
        }
        let matchingDict = matchingDictUM! as NSMutableDictionary
        matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]

        var matchingServices : io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
            return nil
        }

        return matchingServices
    }

    // Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
    // If no interfaces are found the MAC address is set to an empty string.
    // In this sample the iterator should contain just the primary interface.
    private static func GetMACAddress(intfIterator : io_iterator_t) -> [UInt8]? {

        var macAddress : [UInt8]?

        var intfService = IOIteratorNext(intfIterator)
        while intfService != 0 {

            var controllerService : io_object_t = 0
            if IORegistryEntryGetParentEntry(intfService, "IOService", &controllerService) == KERN_SUCCESS {

                let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
                if dataUM != nil {
                    let data = dataUM!.takeRetainedValue() as! NSData
                    macAddress = [0, 0, 0, 0, 0, 0]
                    data.getBytes(&macAddress!, length: macAddress!.count)
                }
                IOObjectRelease(controllerService)
            }

            IOObjectRelease(intfService)
            intfService = IOIteratorNext(intfIterator)
        }

        return macAddress
    }
}

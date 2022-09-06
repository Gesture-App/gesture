//
//  BluetoothView.swift
//  Gesture
//
//  Created by Jacky Zhao on 2022-08-22.
//

import Foundation
import SwiftUI
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    @Published var isBluetoothEnabled = false
    @Published var isAdvertising = false
    @Published public var pairedTo: Optional<CBCentral> = nil
    
    let serviceUUID = "f4f8cc56-30e7-4a68-9d38-da0b16a20e82"
    var service: CBMutableService!
    public var peripheralManager: CBPeripheralManager!
    var handsCharacteristic: CBMutableCharacteristic!
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    public func toggleAdvertisement() {
        if isBluetoothEnabled {
            peripheralManager.stopAdvertising()
            if !isAdvertising {
                peripheralManager.startAdvertising([
                    CBAdvertisementDataLocalNameKey: "Gesture: Controller",
                    CBAdvertisementDataServiceUUIDsKey : [service.uuid]
                ])
            }
            isAdvertising = !isAdvertising
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // ensure bluetooth is on
        if peripheral.state == .poweredOn {
            let serviceCBUUID = CBUUID(string: serviceUUID)
            service = CBMutableService(type: serviceCBUUID, primary: true)
            handsCharacteristic = CBMutableCharacteristic.init(
                type: serviceCBUUID,
                properties: [.writeWithoutResponse, .notify, .read],
                value: nil,
                permissions: [.readable, .writeable]
            )
            service.characteristics = [handsCharacteristic]
            peripheralManager.add(service)
            isBluetoothEnabled = true
        } else {
            isBluetoothEnabled = false
        }
    }
    
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        pairedTo = central
        peripheralManager.setDesiredConnectionLatency(.low, for: central)
        peripheralManager.stopAdvertising()
        isAdvertising = false
    }
}

//
//  BluetoothManager.swift
//  Gesture
//
//  Created by Jacky Zhao on 2022-08-22.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    @Published var isBluetoothEnabled = false
    @Published var isAdvertising = false
    
    let serviceUUID = "f4f8cc56-30e7-4a68-9d38-da0b16a20e82"
    var service: CBMutableService!
    var peripheralManager: CBPeripheralManager!
    var handsCharacteristic: CBMutableCharacteristic!
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    public func toggleAdvertisement() {
        if !isAdvertising {
            peripheralManager.startAdvertising([
                CBAdvertisementDataLocalNameKey: "Gesture: Controller",
                CBAdvertisementDataServiceUUIDsKey : [service.uuid]
            ])
        } else {
            peripheralManager.stopAdvertising()
        }
        isAdvertising = !isAdvertising
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // ensure bluetooth is on
        if peripheral.state == .poweredOn {
            isBluetoothEnabled = true
            let serviceCBUUID = CBUUID(string: serviceUUID)
            service = CBMutableService(type: serviceCBUUID, primary: true)
            handsCharacteristic = CBMutableCharacteristic.init(
                type: serviceCBUUID,
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
            service.characteristics = [handsCharacteristic]
            peripheralManager.add(self.service)
        } else {
            isBluetoothEnabled = false
        }
    }
}

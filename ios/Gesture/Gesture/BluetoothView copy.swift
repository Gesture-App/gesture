//
//  BluetoothView.swift
//  Gesture
//
//  Created by Jacky Zhao on 2022-08-22.
//

import SwiftUI
import Foundation
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {
    let serviceUUID = "F4F8CC56-30E7-4A68-9D38-DA0B16A20E82"
    
    var peripheralManager: CBPeripheralManager!
    var service:
        CBMutableService!
    var handsCharacteristic: CBMutableCharacteristic

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // ensure bluetooth is on
        if peripheral.state == .poweredOn {
            let serviceCBUUID = CBUUID(string: serviceUUID)
            service = CBMutableService(type: serviceCBUUID, primary: true)
            handsCharacteristic = CBMutableCharacteristic.init(
                type: serviceCBUUID,
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
            
            service.characteristics = [handsCharacteristic]
            peripheralManager.add(self.service)
            peripheralManager.startAdvertising([
                CBAdvertisementDataLocalNameKey: "Gesture: Controller",
                CBAdvertisementDataServiceUUIDsKey : [self.service.uuid]
            ])
        }
    }
    
    func writeDataToCharacteristic(data: Data) {
        peripheralManager.updateValue(data, for: handsCharacteristic, onSubscribedCentrals: nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
         if let error = error {
            print("Add service failed: \(error.localizedDescription)")
            return
        }
        print("Add service succeeded")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Start advertising failed: \(error.localizedDescription)")
            return
        }
        print("Start advertising succeeded")
    }
}

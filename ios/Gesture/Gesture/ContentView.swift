//
//  ContentView.swift
//  Gesture
//
//  Created by Jacky Zhao on 2022-08-22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    
    var body: some View {
        VStack (spacing: 10) {
            Text("👋 Gesture")
                .font(.largeTitle)
                .padding()
            Button(action: bluetoothManager.toggleAdvertisement) {
                if bluetoothManager.isAdvertising {
                    Text("Stop advertising").foregroundColor(.red)
                } else {
                    Text("Start pairing to device")
                }
            }
        }.padding()
        VStack {
            if bluetoothManager.isBluetoothEnabled {
                Text("Bluetooth: On")
                    .foregroundColor(.green)
            }
            else {
                Text("Bluetooth: Off")
                    .foregroundColor(.red)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

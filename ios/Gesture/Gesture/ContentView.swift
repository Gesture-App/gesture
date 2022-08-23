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
        NavigationView {
            VStack (spacing: 20) {
                Text("👋 Gesture")
                    .font(.largeTitle)
                
                VStack {
                    if let receiver = bluetoothManager.pairedTo {
                        NavigationLink(destination: ARViewContainer().edgesIgnoringSafeArea(.all)) {
                            Text("Start gesture recognition")
                        }.buttonStyle(.borderedProminent)
                    } else {
                        Button(action: bluetoothManager.toggleAdvertisement) {
                            if bluetoothManager.isAdvertising {
                                Text("Stop advertising").foregroundColor(.red)
                            } else {
                                Text("Start pairing to device").disabled(!bluetoothManager.isBluetoothEnabled)
                            }
                        }.buttonStyle(.bordered).font(.headline)
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
                    if bluetoothManager.pairedTo != nil {
                        Text("Paired Successfully")
                            .foregroundColor(.green)
                    } else {
                        Text("Not paired yet")
                    }
                }
            }
        }
        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

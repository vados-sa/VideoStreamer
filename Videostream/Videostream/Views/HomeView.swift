//
//  HomeView.swift
//  Videostream
//
//  Created by dos Santos, Vanessa on 03.08.26.
//

import SwiftUI


struct HomeView: View {
//    @State private var isStreaming = false // control camera sheet visibility
    @StateObject private var model = FrameHandler()
    @State private var showTelemetry = false
    
    var body: some View {
        ZStack(alignment: .bottom){

            if model.isRunning {
                FrameView(image: model.frame)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                Button(model.isRunning ? "Stop Streaming" : "Start Streaming") {
                    if model.isRunning {
                        model.stop()
                        showTelemetry = true
                    } else {
                        model.start()
                    }
                    
                }
                .font(.headline)
                .padding()
                .background(Color(red: 226/255, green: 0, blue: 116/255))
                .foregroundStyle(.white)
                .cornerRadius(25)
            }
        }
        .fullScreenCover(isPresented: $showTelemetry) {
            TelemetryView(telemetryData: $model.telemetryData)
        }
    }
}


#Preview {
    HomeView()
}

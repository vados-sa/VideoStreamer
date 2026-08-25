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
    
    var body: some View {
        ZStack(alignment: .bottom){

            if model.isRunning {
                FrameView(image: model.frame)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea() // might be where I disply telemtry data
            }
            
            VStack {
                Spacer()
                Button(model.isRunning ? "Stop Streaming" : "Start Streaming") {
                    model.isRunning ? model.stop() : model.start()
                }
                .font(.headline)
                .padding()
                .background(Color(red: 226/255, green: 0, blue: 116/255))
                .foregroundStyle(.white)
                .cornerRadius(25)
            }
        }
    }
}


#Preview {
    HomeView()
}

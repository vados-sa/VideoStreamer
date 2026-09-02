//
//  FrameView.swift
//  LiveStream
//
//  Created by dos Santos, Vanessa on 07.08.26.
//

import SwiftUI

// where the capture view will be displayed (live)
struct FrameView: View {
    var image: CGImage? /// takes the image as GCImage (optinal)
    private let label = Text("frame") /// identify the image
    
    var body: some View {
            Group {
                if let image {
                    Image(image, scale: 1.0, orientation: .up, label: label)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea() /// might be where I display telemetry data
                }
            }
            .clipped()
        }
}

#Preview {
    FrameView()
}

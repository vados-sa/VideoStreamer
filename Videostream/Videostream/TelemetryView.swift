//
//  TelemetryView.swift
//  Videostream
//
//  Created by Vanessa dos Santos on 28.08.26.
//

import SwiftUI

struct TelemetryView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var telemetryData: String

    var body: some View {
        Color(red: 226/255, green: 0, blue: 116/255)
            .ignoresSafeArea()
            .overlay(
                VStack (alignment: .trailing) {
                    Button {
                        // clean telemetry data
                        dismiss()
                    } label: {
                        Image(systemName: "multiply")
                            .foregroundColor(Color(red: 226/255, green: 0, blue: 116/255))
                            .font(.title)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    ScrollView {
                        Text(telemetryData)
                            .fixedSize(horizontal: false, vertical: true)
//                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(width: 350)
                            .background(Rectangle().fill(Color.white).shadow(radius: 3))
                    }
                }
                .background(Color(red: 226/255, green: 0, blue: 116/255))
            )

    }
}

#Preview {
    TelemetryView(telemetryData: .constant("Preview telemetry text"))
}

//
//  TelemetryView.swift
//  Videostream
//
//  Created by Vanessa dos Santos on 28.08.26.
//

import SwiftUI

struct TelemetryView: View {
    @Environment(\.dismiss) var dismiss
    
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
                        Text(" Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam non lacus volutpat, dapibus elit vitae, maximus nibh. Curabitur lobortis sodales nisi sed efficitur. Sed sit amet ante bibendum, accumsan sem nec, luctus ipsum. Nulla eget tortor sodales, iaculis elit a, vehicula quam. Mauris finibus neque tristique sem cursus aliquet. Donec id malesuada nunc. Donec id ornare ante, eget sollicitudin risus.\n Aliquam ut interdum purus. Nullam pulvinar tincidunt rhoncus. Proin feugiat est nec justo feugiat pretium. Maecenas porttitor malesuada dignissim. Aliquam sed ultricies enim, sed mollis lectus. Donec semper justo et ante cursus convallis. Mauris vel neque at nulla placerat tempor. Donec vulputate sem eu urna molestie varius. Proin ullamcorper, nisl in viverra dignissim, leo augue eleifend augue, quis sollicitudin nisl ligula ut ligula.\n Morbi commodo, enim volutpat varius hendrerit, nibh elit tincidunt augue, et porta ligula felis at orci. Nam id libero ut leo feugiat pulvinar vitae sed dui. Aenean ante leo, porta eget leo nec, sodales interdum risus. Etiam posuere nibh elit, in rhoncus nibh venenatis nec. Proin velit justo, euismod et auctor in, ultricies quis felis. Interdum et malesuada fames ac ante ipsum primis in faucibus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac augue ut felis euismod tempor. Proin facilisis libero nec ligula scelerisque, ac varius urna varius. Nunc vel tortor id diam sagittis feugiat vel a nibh. Proin malesuada felis ac pretium eleifend. Cras congue dapibus sem, non faucibus felis finibus at.\n Etiam laoreet elit a euismod tempor. Donec scelerisque vitae mi nec iaculis. Sed vulputate diam vitae iaculis pharetra. Nulla turpis erat, porttitor ac eleifend et, ornare et neque. Duis nec rhoncus tortor. Nunc convallis vestibulum elit, eget dapibus odio euismod id. Donec elementum metus sit amet pulvinar rhoncus. Suspendisse nunc dolor, ultricies vitae tortor non, ornare ullamcorper odio.\n") // Telemetry data comes here
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
    TelemetryView()
}

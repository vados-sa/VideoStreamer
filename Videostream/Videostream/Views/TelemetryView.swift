//
//  TelemetryView.swift
//  Videostream
//
//  Created by Vanessa dos Santos on 28.08.26.
//

import SwiftUI

struct TelemetryView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var telemetryLog: [TelemetryReading]

    var body: some View {
        Color(red: 226/255, green: 0, blue: 116/255)
            .ignoresSafeArea()
            .overlay(
                VStack (alignment: .trailing) {
                    Button {
                        telemetryLog = []
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
                        VStack(spacing: 12) {
                            ForEach(telemetryLog) { reading in
                                TelemetryCard(reading: reading)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .background(Color(red: 226/255, green: 0, blue: 116/255))
            )

    }
}

private struct TelemetryCard: View {
    let reading: TelemetryReading

    var body: some View {
        Group {
            if let errorMessage = reading.errorMessage {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    TelemetryRow(label: "Time", value: formattedTimestamp)
                    TelemetryRow(label: "Uptime", value: formattedUptime)
                    TelemetryRow(label: "Memory", value: formattedMemory)
                    TelemetryRow(label: "Requests", value: reading.requestCount.map(String.init) ?? "—")
                }
            }
        }
        .padding()
        .frame(width: 350, alignment: .leading)
        .background(Rectangle().fill(Color.white).shadow(radius: 3))
    }

    private var formattedTimestamp: String {
        guard let timestamp = reading.timestamp else { return "—" }
        let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: timestamp) {
                return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
            }
        }
        return timestamp
    }

    private var formattedUptime: String {
        guard let uptimeMillis = reading.uptimeMillis else { return "—" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(uptimeMillis) / 1000) ?? "—"
    }

    private var formattedMemory: String {
        guard let usedMemoryBytes = reading.usedMemoryBytes,
              let maxMemoryBytes = reading.maxMemoryBytes
        else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        let used = formatter.string(fromByteCount: Int64(usedMemoryBytes))
        let max = formatter.string(fromByteCount: Int64(maxMemoryBytes))
        return "\(used) / \(max)"
    }
}

private struct TelemetryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    TelemetryView(telemetryLog: .constant([
        TelemetryReading(
            timestamp: "2026-09-07T12:34:56.789",
            uptimeMillis: 123_456,
            usedMemoryBytes: 512_000_000,
            maxMemoryBytes: 4_294_967_296,
            requestCount: 42,
            errorMessage: nil
        ),
        TelemetryReading(
            timestamp: nil,
            uptimeMillis: nil,
            usedMemoryBytes: nil,
            maxMemoryBytes: nil,
            requestCount: nil,
            errorMessage: "Telemetry server unavailable"
        )
    ]))
}

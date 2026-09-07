//
//  TelemetryReading.swift
//  Videostream
//

import Foundation

struct TelemetryReading: Decodable, Identifiable {
    let id = UUID()

    let timestamp: String?
    let uptimeMillis: Int?
    let usedMemoryBytes: Int?
    let maxMemoryBytes: Int?
    let requestCount: Int?
    let errorMessage: String?

    private enum CodingKeys: String, CodingKey {
        case timestamp, uptimeMillis, usedMemoryBytes, maxMemoryBytes, requestCount
        case errorMessage = "message"
    }
}

struct TelemetryEnvelope: Decodable {
    let type: String
    let data: TelemetryReading
}

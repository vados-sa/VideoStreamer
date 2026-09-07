//
//  WebSocketManager.swift
//  Videostream
//
//  Created by dos Santos, Vanessa on 25.08.26.
//

import Foundation


class WebSocketManager: NSObject {

    private let url: URL

    // Kept alive for the whole lifetime of the manager so it can vend a fresh
    // webSocketTask on every connect(). Invalidated only in deinit.
    private let urlSession: URLSession

    // Serializes access to webSocketTask / isConnected: connect()/disconnect()
    // run on the caller's queue while the receive completion handlers run on another.
    private let stateQueue = DispatchQueue(label: "websocket.state.queue")
    private var webSocketTask: URLSessionWebSocketTask?

    // Tracks whether we intend to be connected. Lets the receive loop tell an
    // intentional disconnect() apart from a genuine socket failure.
    private var isConnected = false

    var onReceiveMessage: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?

    init(url: URL) {
        self.url = url

        // A standalone delegate object avoids the URLSession -> delegate -> self
        // retain cycle that would otherwise keep this manager alive forever.
        let delegate = SessionDelegate()
        self.urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())

        super.init()
        print("WebSocketMessenger initialized for: \(url.absoluteString)")
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    func connect() {
        stateQueue.sync {
            // Drop any stale task before building a fresh one.
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)

            let task = self.urlSession.webSocketTask(with: self.url)
            self.webSocketTask = task
            self.isConnected = true
            task.resume()
        }
        print("Attempting to connect to WebSocket...")
        receiveMessage() // Start listening for incoming messages immediately
    }

    func disconnect() {
        stateQueue.sync {
            self.isConnected = false
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            self.webSocketTask = nil
        }
        print("WebSocket disconnected.")
    }

    func sendFrames(frames: Data) {
        let task = stateQueue.sync { isConnected ? webSocketTask : nil }
        guard let task else { return }
        let message = URLSessionWebSocketTask.Message.data(frames)
        task.send(message) { error in
            if let error = error {
                print("Error sending frames: \(error.localizedDescription)")
            } else {
                print("Frames sent.")
            }
        }
    }

    private func receiveMessage() {
        let task = stateQueue.sync { isConnected ? webSocketTask : nil }
        guard let task else { return }

        task.receive { [weak self] result in
            guard let self else {return}

            switch result {
            case .success:
                self.onReceiveMessage?(result)
                // Recursively call receive to listen for the next message
                self.receiveMessage()
            case .failure(let error):
                // A cancellation triggered by our own disconnect() is expected —
                // stay quiet. Only report a drop we didn't ask for.
                let wasConnected = self.stateQueue.sync { () -> Bool in
                    let connected = self.isConnected
                    self.isConnected = false
                    return connected
                }
                guard wasConnected else { return }

                self.onReceiveMessage?(result) // Report the error
                print("Error receiving message: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

/// Separate from `WebSocketManager` so `URLSession`'s strong hold on its delegate
/// doesn't create a retain cycle. Purely diagnostic logging.
private final class SessionDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) }
        print("WebSocket closed with code: \(closeCode.rawValue), reason: \(reasonString ?? "(none)")")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? URLError {
            print("WebSocket session failed with error: \(error.localizedDescription)")
        } else if let error = error {
            print("WebSocket session failed with generic error: \(error.localizedDescription)")
        }
    }
}

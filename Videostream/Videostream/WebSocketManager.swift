//
//  WebSocketManager.swift
//  Videostream
//
//  Created by dos Santos, Vanessa on 25.08.26.
//

import Foundation


class WebSocketManager: NSObject, URLSessionWebSocketDelegate{
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    var onReceiveMessage: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?
    
    init(url: URL) {
        super.init()
        
        // Use a background queue for delegate calls to avoid blocking the main thread
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.urlSession = session
        
        self.webSocketTask = session.webSocketTask(with: url)
        print("WebSocketMessenger initialized for: \(url.absoluteString)")
    }
    
    func connect() {
        self.webSocketTask?.resume()
        print("Attempting to connect to WebSocket...")
        receiveMessage() // Start listening for incoming messages immediately
    }
    
    func disconnect() {
        self.webSocketTask?.cancel(with: .goingAway, reason: nil)
        self.urlSession?.invalidateAndCancel()
        print("WebSocket disconnected.")
    }
    
    func sendMessage(text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            } else {
                print("Sent message: \(text)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self else {return}
            
            switch result {
            case .success(let message):
                self.onReceiveMessage?(result)
                // Recursively call receive to listen for the next message
                self.receiveMessage()
            case .failure(let error):
                self.onReceiveMessage?(result) // Report the error
                print("Error receiving message: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - URLSessionSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        print("WebSocket connected")
        sendMessage(text: "Hi")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason != nil ? String(data: reason!, encoding: .utf8) : nil
        print("WebSocket closed with code: \(closeCode.rawValue), reason: \(reasonString ?? "(none)")")
        self.webSocketTask = nil
        self.urlSession = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? URLError {
            print("WebSocket session failed with error: \(error.localizedDescription)")
        } else if let error = error {
            print("WebSocket session failed with generic error: \(error.localizedDescription)")
        }
    }

//    func sendFrameToServer(/*sampleBuffer: CMSampleBuffer*/message: String) {
//        //print(sampleBuffer)
//        
//        self.connect()
//        // send message
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.sendMessage(text: message)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
//            self.disconnect()
//        }
//        
////        if let url = URL(string: "ws://192.168.178.69:8000/ws/videostream") {
////            let manager = WebSocketManager(url: url)
////
////        }
//    }
    
}

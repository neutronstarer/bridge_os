//
//  ViewController.swift
//  Example
//
//  Created by neutronstarer on 2020/9/3.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

import Bridgeos
import UIKit
import WebKit
import SnapKit
import GCDWebServer

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var connections = Dictionary<String, BridgeosConnection>()
    var webServer: GCDWebServer!
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webServer = {()->GCDWebServer in
            let v = GCDWebServer()
            v.addGETHandler(forBasePath: "/", directoryPath: Bundle(path: Bundle.main.path(forResource: "WWW", ofType: "bundle")!)?.resourcePath ?? "", indexFilename: nil, cacheAge: 0, allowRangeRequests: false)
            GCDWebServer.setLogLevel(4)
            v.start(withPort: 8080, bonjourName: nil)
            return v
        }()
        webView = {() -> WKWebView in
            let v = WKWebView()
            v.navigationDelegate = self
            v.uiDelegate = self
            return v
        }()
        
        self.view.addSubview(webView)
        
        webView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        let server = BridgeosServer.server(webView: webView as Any, name: nil)
        
        server?.on("connect").event({[weak self] (connection, payload, ack) -> Any? in
            NSLog("\(connection.connectionId) connected")
            self?.connections[connection.connectionId] = connection
            return nil
        })
        server?.on("disconnect").event({[weak self] (connection, payload, ack) -> Any? in
            NSLog("\(connection.connectionId) disconnected")
            self?.connections[connection.connectionId] = nil
            return nil
        })
        server?.on("request").event({ (connection, payload, ack) -> Any? in
            NSLog("receive request \(payload ?? "")")
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + .seconds(2), repeating:1)
            timer.setEventHandler {[weak timer] in
                let res = "[\\] [\'] [\"] [\r] [\n] [\t] [\u{2028}] [\u{2029}]"
                ack(res, nil)
                NSLog("ack \(res)")
                timer?.cancel()
            }
            timer.resume()
            return timer
        }).cancel({ (timer) in
            guard let timer = timer as! DispatchSource? else{
                return
            }
            timer.cancel()
            NSLog("do cancel")
        })
        webView.load(URLRequest(url: URL(string: "http://localhost:8080/index.html")!))
        // Do any additional setup after loading the view.
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if BridgeosServer.canHandle(webView: webView, URLString: navigationAction.request.url?.absoluteString) {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}


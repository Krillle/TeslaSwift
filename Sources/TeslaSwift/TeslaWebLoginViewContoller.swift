//
//  TeslaWebLoginViewController.swift
//  TeslaSwift
//
//  Created by João Nunes on 22/11/2020.
//  Copyright © 2020 Joao Nunes. All rights reserved.
//

#if canImport(WebKit) && canImport(UIKit)
import WebKit

public class TeslaWebLoginViewController: UIViewController {
    var webView = WKWebView()
    private var continuation: CheckedContinuation<URL, Error>?

    required init?(coder: NSCoder) {
        fatalError("not supported")
    }

    init(url: URL) {
        super.init(nibName: nil, bundle: nil)

        // Enable AutoFill Passwords 
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        if #available(iOS 11.0, *) {
            config.websiteDataStore.isPersistent = true
        }        
        webView = WKWebView(frame: .zero, configuration: config)
        
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
    }

    override public func loadView() {
        view = webView
    }

    func result() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
}

extension TeslaWebLoginViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.localizedStandardContains("code=") {
            decisionHandler(.cancel)
            self.dismiss(animated: true) {
                self.continuation?.resume(returning: url)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.dismiss(animated: true) {
            self.continuation?.resume(throwing: TeslaError.authenticationFailed)
        }
    }
}

extension TeslaWebLoginViewController {
    static func removeCookies() {
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}
#endif

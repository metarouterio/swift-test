import Foundation

class SegmentBlockerURLProtocol: URLProtocol {
    // List of domains to block
    static let blockedDomains = ["cdn-settings.segment.com"]
    
    // Register this protocol with the URL loading system
    static func register() {
        URLProtocol.registerClass(self)
    }
    
    // Determine if this protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, let host = url.host else { return false }
        return blockedDomains.contains { host.contains($0) }
    }
    
    // This is needed but just returns the request unchanged
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    // Instead of loading the request, we'll return a mock response
    override func startLoading() {
        guard let url = request.url else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        // Create a mock 404 response
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        
        // Send the mocked response to the client
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        // Mock empty data
        let data = Data("{\"error\": \"Not Found\"}".utf8)
        client?.urlProtocol(self, didLoad: data)
        
        // Mark the request as complete
        client?.urlProtocolDidFinishLoading(self)
    }
    
    // Required but does nothing in our case
    override func stopLoading() {
        // Not needed for our implementation
    }
}

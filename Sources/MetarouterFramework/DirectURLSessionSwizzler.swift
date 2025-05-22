import Foundation

class DirectURLSessionSwizzler {
    // Control flags
    nonisolated(unsafe) static var isBlockingEnabled = false
    nonisolated(unsafe) static var blockOnlyNextRequest = false
    nonisolated(unsafe) static var blockedDomains: Set<String> = ["cdn-settings.segment.com"]
    nonisolated(unsafe) static var isSwizzled = false
    
    static func setupSegmentBlocking() {
        guard !isSwizzled else { return } // Prevent double-swizzling
        swizzleDataTaskWithRequest()
        swizzleDataTaskWithURL()
        isSwizzled = true
    }
    
    // Enable blocking for all requests
    static func enableBlocking() {
        isBlockingEnabled = true
        blockOnlyNextRequest = false
    }
    
    // Disable all blocking
    static func disableBlocking() {
        isBlockingEnabled = false
        blockOnlyNextRequest = false
    }
    
    // Block only the next request to blocked domains
    static func blockNextRequest() {
        // Auto-setup if not already done
        if !isSwizzled {
            setupSegmentBlocking()
        }
        blockOnlyNextRequest = true
        isBlockingEnabled = true
    }
    
    // Add/remove domains dynamically
    static func addBlockedDomain(_ domain: String) {
        blockedDomains.insert(domain)
    }
    
    static func removeBlockedDomain(_ domain: String) {
        blockedDomains.remove(domain)
    }
    
    private static func swizzleDataTaskWithRequest() {
        let urlSessionClass = URLSession.self
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector = #selector(URLSession.swizzled_dataTaskWithRequest(with:completionHandler:))
        
        if let originalMethod = class_getInstanceMethod(urlSessionClass, originalSelector),
           let swizzledMethod = class_getInstanceMethod(urlSessionClass, swizzledSelector) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    private static func swizzleDataTaskWithURL() {
        let urlSessionClass = URLSession.self
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URL, @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector = #selector(URLSession.swizzled_dataTaskWithURL(with:completionHandler:))
        
        if let originalMethod = class_getInstanceMethod(urlSessionClass, originalSelector),
           let swizzledMethod = class_getInstanceMethod(urlSessionClass, swizzledSelector) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension URLSession {
    @objc func swizzled_dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        // Check if this request should be blocked
        if shouldBlockRequest(request) {
            print("🚫 Blocked network request to: \(request.url?.absoluteString ?? "unknown")")
            
            // If we're only blocking next request, disable blocking after this one
            if DirectURLSessionSwizzler.blockOnlyNextRequest {
                DirectURLSessionSwizzler.isBlockingEnabled = false
                DirectURLSessionSwizzler.blockOnlyNextRequest = false
            }
            
            // Return a cancelled task that never executes
            let dummyRequest = URLRequest(url: URL(string: "data:,")!)
            let task = self.swizzled_dataTaskWithRequest(with: dummyRequest) { _, _, _ in }
            
            task.cancel()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [
                    NSLocalizedDescriptionKey: "Request blocked by DirectURLSessionSwizzler"
                ])
                completionHandler(nil, nil, error)
            }
            
            return task
        }
        
        return self.swizzled_dataTaskWithRequest(with: request, completionHandler: completionHandler)
    }
    
    @objc func swizzled_dataTaskWithURL(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        let request = URLRequest(url: url)
        
        if shouldBlockRequest(request) {
            print("🚫 Blocked network request to: \(url.absoluteString)")
            
            // If we're only blocking next request, disable blocking after this one
            if DirectURLSessionSwizzler.blockOnlyNextRequest {
                DirectURLSessionSwizzler.isBlockingEnabled = false
                DirectURLSessionSwizzler.blockOnlyNextRequest = false
            }
            
            let dummyURL = URL(string: "data:,")!
            let task = self.swizzled_dataTaskWithURL(with: dummyURL) { _, _, _ in }
            
            task.cancel()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [
                    NSLocalizedDescriptionKey: "Request blocked by DirectURLSessionSwizzler"
                ])
                completionHandler(nil, nil, error)
            }
            
            return task
        }
        
        return self.swizzled_dataTaskWithURL(with: url, completionHandler: completionHandler)
    }
    
    private func shouldBlockRequest(_ request: URLRequest) -> Bool {
        // First check if blocking is enabled
        guard DirectURLSessionSwizzler.isBlockingEnabled else { return false }
        
        guard let url = request.url,
              let host = url.host else { return false }
        
        return DirectURLSessionSwizzler.blockedDomains.contains { host.contains($0) }
    }
}

// MARK: - Usage Examples
/*
// Simple usage - just call this before making a request you want to block:
DirectURLSessionSwizzler.blockNextRequest()
// The swizzling will be automatically set up on first use

// Or you can still manually setup if you prefer:
DirectURLSessionSwizzler.setupSegmentBlocking()

// Other options still available:
DirectURLSessionSwizzler.enableBlocking()
DirectURLSessionSwizzler.disableBlocking()
DirectURLSessionSwizzler.addBlockedDomain("another-domain.com")
*/

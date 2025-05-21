import Foundation

class DirectURLSessionSwizzler {
    static func setupSegmentBlocking() {
        swizzleDataTaskWithRequest()
        swizzleDataTaskWithURL()
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
            
            // Return a cancelled task that never executes
            let dummyRequest = URLRequest(url: URL(string: "data:,")!) // Data URL that resolves immediately
            let task = self.swizzled_dataTaskWithRequest(with: dummyRequest) { _, _, _ in }
            
            // Immediately cancel the task so it never executes
            task.cancel()
            
            // Call completion handler with error after a short delay to simulate network behavior
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [
                    NSLocalizedDescriptionKey: "Request blocked by DirectURLSessionSwizzler"
                ])
                completionHandler(nil, nil, error)
            }
            
            return task
        }
        
        // For non-blocked requests, proceed normally
        return self.swizzled_dataTaskWithRequest(with: request, completionHandler: completionHandler)
    }
    
    @objc func swizzled_dataTaskWithURL(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        // Create a request to check if it should be blocked
        let request = URLRequest(url: url)
        
        if shouldBlockRequest(request) {
            print("🚫 Blocked network request to: \(url.absoluteString)")
            
            // Return a cancelled task that never executes
            let dummyURL = URL(string: "data:,")! // Data URL that resolves immediately
            let task = self.swizzled_dataTaskWithURL(with: dummyURL) { _, _, _ in }
            
            // Immediately cancel the task
            task.cancel()
            
            // Call completion handler with error
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [
                    NSLocalizedDescriptionKey: "Request blocked by DirectURLSessionSwizzler"
                ])
                completionHandler(nil, nil, error)
            }
            
            return task
        }
        
        // For non-blocked requests, proceed normally
        return self.swizzled_dataTaskWithURL(with: url, completionHandler: completionHandler)
    }
    
    private func shouldBlockRequest(_ request: URLRequest) -> Bool {
        guard let url = request.url,
              let host = url.host else { return false }
        
        let blockedDomains = ["cdn-settings.segment.com"]
        return blockedDomains.contains { host.contains($0) }
    }
}

//
//  Created by Christopher Houdlette on 5/21/25.
//

import Foundation
import Segment

public class MetaRouterFramework {
    // Keep the analytics instance private
    private let analytics: Analytics
    
    public init(writeKey: String, clusterHost: String) {
        
        SegmentBlockerURLProtocol.register()
        
        let configuration = Configuration(writeKey: writeKey)
            .trackApplicationLifecycleEvents(true)
            .flushInterval(10)
            .apiHost(clusterHost)
        
        self.analytics = Analytics(configuration: configuration)
    }
    
    // Provide convenience methods with clear naming
    public func track(event: String, properties: [String: Any]? = nil) {
        analytics.track(name: event, properties: properties)
    }
    
    public func identify(userId: String, traits: [String: Any]? = nil) {
        analytics.identify(userId: userId, traits: traits)
    }
    
    public func screen(title: String, properties: [String: Any]? = nil) {
        analytics.screen(title: title, properties: properties)
    }
    
}

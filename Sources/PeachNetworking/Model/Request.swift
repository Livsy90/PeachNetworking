import Foundation

public struct Request: Identifiable, Hashable, Sendable {
    
    public enum HTTPScheme: String, Equatable, Hashable, Sendable {
        case http
        case https
    }
    
    public enum HTTPMethod: String, Equatable, Hashable, Sendable {
        case connect
        case delete
        case get
        case head
        case options
        case patch
        case post
        case put
        case trace
    }
    
    public let id: UUID
    public let url: URL
    public let scheme: HTTPScheme
    public let host: String
    public let path: String
    public let parameters: [String: String]
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let cachePolicy: NSURLRequest.CachePolicy
    public let timeout: TimeInterval
    
    var urlRequest: URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpMethod = method.rawValue.uppercased()
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        
        return request
    }
    
    public init(
        id: UUID = .init(),
        url: URL?,
        method: HTTPMethod = .get,
        headers: [String: String] = .init(),
        body: Data? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 120
    ) throws {
        guard let url else {
            throw URLError(.badURL)
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        
        guard let rawScheme = components.scheme, let scheme = HTTPScheme(rawValue: rawScheme) else {
            throw URLError(.unsupportedURL)
        }
        
        guard let host = components.host else {
            throw URLError(.badURL)
        }
        
        self.id = id
        self.url = url
        self.scheme = scheme
        self.host = host
        self.path = components.path
        self.parameters = components.queryItems?.reduce(into: [String: String]()) { result, item in
            if let value = item.value {
                result[item.name] = value
            }
        } ?? [:]
        self.method = method
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
    }
    
    public init(
        id: UUID = .init(),
        scheme: HTTPScheme = .https,
        host: String,
        path: String = "/",
        parameters: [String: String] = .init(),
        method: HTTPMethod = .get,
        headers: [String: String] = .init(),
        body: Data? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 120
    ) throws {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = host
        components.path = path.first == "/" ? path : "/" + path
        components.queryItems = parameters.isEmpty ? nil : parameters.reduce(into: [URLQueryItem]()) { result, item in
            result.append(URLQueryItem(name: item.key, value: item.value))
        }
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        self.id = id
        self.url = url
        self.scheme = scheme
        self.host = host
        self.path = path.first == "/" ? path : "/" + path
        self.parameters = parameters
        self.method = method
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
    }
    
}

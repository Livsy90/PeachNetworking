import Foundation

public struct Response: Identifiable, Hashable, Sendable {
    
    public enum Status: String, Equatable, Hashable, Sendable {
        case invalid
        case information
        case success
        case redirection
        case clientError
        case serverError
    }
    
    public let id: UUID
    public let code: Int
    public let headers: [String: String]
    public let body: Data
    
    public var status: Status {
        switch self.code {
        case 100...199: .information
        case 200...299: .success
        case 300...399: .redirection
        case 400...499: .clientError
        case 500...599: .serverError
        default: .invalid
        }
    }
    
    public var isSuccess: Bool {
        status == .success
    }
    
    init(
        id: UUID = .init(),
        httpURLResponse: HTTPURLResponse,
        body: Data
    ) {
        self.id = id
        self.code = httpURLResponse.statusCode
        self.body = body
        self.headers = httpURLResponse.allHeaderFields.reduce(into: [String: String]()) { result, header in
            if let name = header.key as? String, let value = header.value as? String {
                result[name] = value
            }
        }
    }
    
}

import Foundation

public struct NetworkManager: Sendable {
    
    private let session: URLSession
    
    public init(_ configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
    }
    
    public func send(
        _ request: Request,
        completion: @escaping @Sendable (Result<Response, Error>) -> Void
    ) {
        let task = session.dataTask(with: request.urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data, let httpURLResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            let response = Response(
                httpURLResponse: httpURLResponse,
                body: data
            )
            
            completion(.success(response))
        }
        
        task.resume()
    }
    
    public func send(
        _ request: Request
    ) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            send(request) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func send<T: Decodable & Sendable>(
        _ request: Request,
        decoding model: T.Type,
        using decoder: JSONDecoder = .init(),
        completion: @escaping @Sendable (Result<T, Error>) -> Void
    ) {
        send(request) { result in
            do {
                switch result {
                case .success(let response):
                    guard response.status == .success else {
                        completion(.failure(URLError(.badServerResponse)))
                        return
                    }
                    let model = try decoder.decode(model, from: response.body)
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func send<T: Decodable & Sendable>(
        _ request: Request,
        decoding model: T.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            send(request, decoding: model, using: decoder) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}

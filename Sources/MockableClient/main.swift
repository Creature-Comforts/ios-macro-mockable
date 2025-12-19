import Mockable

@Mockable
protocol APIService {
	func fetchData() -> String
	func upload(data: String)
}

struct CustomResponse {
	
}

@Mockable(associatedTypes: "CustomResponse")
protocol NetworkService<Response> {
	associatedtype Response
	func fetch(completion: @escaping (Result<Response, Error>) -> Void)
}

let networkService = MockNetworkService()
networkService.fetchCalled = true

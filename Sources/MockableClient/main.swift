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

// Protocol inheritance: apply @Mockable to each protocol in the chain. The
// child mock subclasses the parent's generated mock (MockAnimal), inheriting
// its mocked requirements.
@Mockable
protocol Animal {
	func eat()
}

@Mockable
protocol Dog: Animal {
	func bark()
}

let dog = MockDog()
dog.eat()          // inherited from MockAnimal
dog.bark()
print(dog.eatCalled, dog.barkCalled)

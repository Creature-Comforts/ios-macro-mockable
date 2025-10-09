import Mockable

@Mockable
protocol APIService {
	func fetchData() -> String
	func upload(data: String)
}

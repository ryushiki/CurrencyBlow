//
//  ApiController.swift
//  CurrencyBlow
//
//  Created by liuzhihui on 2021/09/21.
//

import Foundation
import RxSwift
import RxCocoa

class WebApiService {

	static var shared = WebApiService()

    private let apiKey = "64cd17d8d1f3563d4b5420c5b6935411"

    let baseURL = URL(string: "http://api.currencylayer.com")!

    func getLiveCurrency(sourceCurrency: String = "USD", sourceAmount: Double, targetCurrencies: [String]) -> Observable<[(String, String)]> {
        var params: [(String, String)] = []
        params.append(("source", sourceCurrency))
        params.append(("currencies", targetCurrencies.joined(separator: ",")))

        return buildRequest(pathComponent: "live", params: params)
            .map { data -> LiveCurrency in
        		let decoder = JSONDecoder()
        		return try decoder.decode(LiveCurrency.self, from: data)
            }
            .map { item in
                var targetResult: [(String, String)] = targetCurrencies.map { result in
                    guard let targetCurrency = item.quotes.first(where: {$0.key == sourceCurrency + result }) else {
                        return (result, "0.0")
                    }
                    return (result, String(targetCurrency.value * sourceAmount))

                }

                targetResult.insert((sourceCurrency, String(sourceAmount)), at: 0)
                return targetResult
            }
    }

    func getCurrencyList() -> Observable<[String]> {
        return buildRequest(pathComponent: "list", params: []).map { data -> CurrencyList in
            let decoder = JSONDecoder()
            return try decoder.decode(CurrencyList.self, from: data)
        }.map { item in
            return Array(item.currencies.keys)
        }
    }

    private func buildRequest(method: String = "GET", pathComponent: String, params:[(String, String)]) -> Observable<Data> {
        let url = baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "access_key", value: apiKey)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!

        if method == "GET" {
            var queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            queryItems.append(keyQueryItem)
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems = [keyQueryItem]

            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }

        request.url = urlComponents.url!
        request.httpMethod = method

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared

        return session.rx.data(request: request)
    }
}

struct LiveCurrency: Decodable {
    let success: Bool
    let source: String
    let quotes: [String : Double]
}

struct CurrencyList: Decodable {
    let success: Bool
    let currencies: [String : String]
}

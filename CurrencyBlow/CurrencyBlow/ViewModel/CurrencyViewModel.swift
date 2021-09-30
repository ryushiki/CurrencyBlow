//
//  CurrencyViewModel.swift
//  CurrencyBlow
//
//  Created by liuzhihui on 2021/09/26.
//

import Foundation
import RxSwift
import RxCocoa
import Action

class CurrencyViewModel {

    var selectedModel: PublishSubject<(Int, String)> = PublishSubject<(Int, String)>()
    var baseAmount: BehaviorSubject<String> = BehaviorSubject<String>(value: "100")

    private(set) var currencyResult: BehaviorSubject<[(String, String)]>
    private(set) var currencyItems: BehaviorSubject<[String]> = BehaviorSubject<[String]>(value: [])
    private(set) var getSupportItems: PublishSubject<[String]> = PublishSubject<[String]>()
    private let disposeBag = DisposeBag()

    init(currencyArray: [String]) {

        let currencyList = WebApiService.shared.getCurrencyList().share()
        currencyList.bind(to: getSupportItems)
            .disposed(by: disposeBag)

        currencyItems = BehaviorSubject<[String]>(value: currencyArray)
        currencyResult = BehaviorSubject.init(value: currencyArray.compactMap({ ($0, "0.0")}))

        getCurrency()
    }

    func getCurrency() {
        let currencyAndBaseAmount = Observable.combineLatest(currencyItems.asObservable(), baseAmount.asObservable())

        currencyAndBaseAmount
            .filter{ $0.0.count > 0}
            .flatMapLatest { (item, baseAmount) in
                WebApiService.shared.getLiveCurrency(sourceAmount: Double(baseAmount) ?? 0.0, targetCurrencies: Array(item[1..<item.count]))
            }.bind(to: currencyResult)
            .disposed(by: disposeBag)

        selectedModel.subscribe(onNext: { (index, name) in
            if var current = try? self.currencyItems.value() {
                current[index] = name
                self.currencyItems.onNext(current)
            }
        }).disposed(by: disposeBag)
    }
}

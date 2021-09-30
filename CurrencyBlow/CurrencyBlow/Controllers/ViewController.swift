//
//  ViewController.swift
//  CurrencyBlow
//
//  Created by liuzhihui on 2021/09/21.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView1: UIPickerView!
    @IBOutlet weak var pickerView2: UIPickerView!
    @IBOutlet weak var pickerView3: UIPickerView!
    @IBOutlet weak var pickerView4: UIPickerView!

    private let disposeBag = DisposeBag()
    private var pickerArray = [UIPickerView]()
    private let currencyArray = ["USD", "AUD", "TZS", "LBP"]
    private let viewModel = CurrencyViewModel.init(currencyArray: ["USD", "AUD", "TZS", "LBP"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        pickerArray = [pickerView1, pickerView2, pickerView3, pickerView4]
        let nib = UINib.init(nibName: "CurrencyTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "CurrencyTableViewCell")
        setPickerDataSource()
		bindOutput()
    }

    func bindOutput() {
        viewModel.currencyResult
            .subscribe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "CurrencyTableViewCell",
                                         cellType: CurrencyTableViewCell.self)) { row, element, cell in
                cell.currencyName.text = element.0
                cell.currencyAmount.text = element.1
                if row == 0 {
                    cell.currencyAmount.rx.controlEvent(.editingDidEndOnExit)
                        .map { cell.currencyAmount.text ?? "" }
                        .filter { !$0.isEmpty }
                        .bind(to: self.viewModel.baseAmount)
                        .disposed(by: self.disposeBag)
                }
            }.disposed(by: disposeBag)
    }
    
    func setPickerDataSource() {
        for (index, item) in pickerArray.enumerated() {
            viewModel.getSupportItems
                .observe(on: MainScheduler.instance)
                .bind(to: item.rx.itemTitles) { _, str in
                    return str
                }
                .disposed(by: disposeBag)

            viewModel.getSupportItems
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { items in
                    if let firstIndex = items.firstIndex(where: { $0 == self.currencyArray[index] }) {
                        item.selectRow(firstIndex, inComponent: 0, animated: false)
                    }
                }).disposed(by: disposeBag)

            item.rx.modelSelected(String.self)
                .map { strs -> (Int, String) in
                	return (index, strs.first ?? "")
                }
                .bind(to: viewModel.selectedModel).disposed(by: disposeBag)
        }
    }

}


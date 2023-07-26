//
//  HistoryView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 23/07/23.
//

import Foundation
import UIKit

class HistoryView: NSObject, TabViewService, UICollectionViewDataSource, UICollectionViewDelegate {
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    deinit {
        print("SE DESTRUYÓ HISTORY VIEW")
    }
    
    unowned var viewController: UIViewController
    private let viewModel = HistoryViewModel()
    private var orders: [Order]?
    private lazy var historyCollectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: .init())
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = .systemBackground
        collection.register(HistoryCollectionViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        return collection
    }()
    
    func setup() {
        viewController.view.addSubview(historyCollectionView)
    }
    
    func reArrangeSubViews() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 300, height: 200)
        layout.minimumLineSpacing = 50
        switch UIDevice.current.orientation {
        case .landscapeLeft: layout.scrollDirection = .horizontal
        case .landscapeRight: layout.scrollDirection = .horizontal
        default: layout.scrollDirection = .vertical
        }
        historyCollectionView.frame = viewController.view.frame
        historyCollectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    func fetchData() {
        viewModel.fetchOrders { [weak self] result in
            switch result {
            case .success(let orders):
                self?.orders = orders
                self?.historyCollectionView.reloadData()
            case .failure(_):
                self?.orders = nil
                self?.historyCollectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        orders?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = historyCollectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as? HistoryCollectionViewCell else { return UICollectionViewCell() }
        if let orders {
            cell.configUICell(orderToDisplay: orders[indexPath.row])
        } else {
            cell.configUICell(header: "\nNo hay \nnada por aquí...", body: "\nAún no has realizado ningún pedido.")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let _ = orders else { return }
        print(indexPath)
    }
}

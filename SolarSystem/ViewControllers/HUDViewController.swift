//
//  HUDViewController.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/14/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit

extension UIView {
    class func initFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?[0] as! T
    }
}

class HUDViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    let HUD = HUDView.instantiate()
    let dataSource = PlanetDataSource()

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = HUD
    }
    
    override func viewDidLoad() {

        let reuse = PlanetCell.reuseIdentifier
        let nib = UINib(nibName: reuse,
                        bundle: nil)
        HUD.collectionView.register(nib,
                                    forCellWithReuseIdentifier: reuse)
        HUD.collectionView.dataSource = dataSource
    }

    override func viewDidLayoutSubviews() {
        if let layout = HUD.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let dimension = HUD.collectionView.frame.size.height
            layout.itemSize = CGSize(width: dimension, height: dimension)
        }
    }
}

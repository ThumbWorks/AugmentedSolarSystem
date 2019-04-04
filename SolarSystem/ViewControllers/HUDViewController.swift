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
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    func update(with distances: [Planet: Float]) {
        if let focusPath = HUD.collectionView.indexPathsForVisibleItems.first {
            let focusPlanet = dataSource.planets[focusPath.row]
            let metersAway = distances[focusPlanet] ?? 0
            HUD.distance.text = "\(metersAway.format(f: ".1")) real meters away"
        }
    }

    override func viewDidLoad() {
        let reuse = PlanetCell.reuseIdentifier
        let nib = UINib(nibName: reuse,
                        bundle: nil)
        HUD.collectionView.register(nib,
                                    forCellWithReuseIdentifier: reuse)
        HUD.collectionView.dataSource = dataSource
        HUD.collectionView.delegate = self
        // set a default value
        let viewModel = Planet.sun.hudViewModel()
        HUD.updateWith(viewModel: viewModel)
    }

    override func viewDidLayoutSubviews() {
        if let layout = HUD.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = HUD.collectionView.frame.size
        }
    }
}

extension HUDViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        guard let indexPath = self.HUD.collectionView.indexPathForItem(at: offset) else {
            return
        }
        let planet = dataSource.planets[indexPath.row]
        HUD.updateWith(viewModel: planet.hudViewModel())
    }
}

extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

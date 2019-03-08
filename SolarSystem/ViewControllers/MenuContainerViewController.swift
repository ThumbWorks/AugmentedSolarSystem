import UIKit

class MenuContainerViewController: UIViewController {
    let menuContainer = MenuContainerView.instantiate()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = menuContainer
    }
}

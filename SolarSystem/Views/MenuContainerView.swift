import UIKit


protocol MenuContainerViewDelegate: class {
    func container(_ view: MenuContainerView, didTapInfoButton button: UIButton)
    func container(_ view: MenuContainerView, didTapDateButton button: UIButton)
    func container(_ view: MenuContainerView, didTapResetButton button: UIButton)
    func container(_ view: MenuContainerView, didTapTogglePathsButton button: UIButton)
    func container(_ view: MenuContainerView, didTapToggleOrbitScaleButton button: UIButton)
    func container(_ view: MenuContainerView, didTapToggleSizeScaleButton button: UIButton)
}

class MenuContainerView: UIView {

    weak var delegate: MenuContainerViewDelegate?

    static func instantiate() -> MenuContainerView {
        let view: MenuContainerView = initFromNib()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    @IBAction func tappedInfo(_ button: UIButton) {
        print("tapped info")
        delegate?.container(self, didTapInfoButton: button)
    }

    @IBAction func toggleDateSelector(_ button: UIButton) {
        delegate?.container(self, didTapDateButton: button)
    }

    @IBAction func resetToDetectedPlane(_ button: UIButton) {
        print("reset to detected plane")
        delegate?.container(self, didTapResetButton: button)
    }

    @IBAction func togglePaths(_ button: UIButton) {
        print("toggle paths")
        delegate?.container(self, didTapTogglePathsButton: button)
    }

    @IBAction func changeOrbitScaleTapped(_ button: UIButton) {
        print("change orbit scale")
        delegate?.container(self, didTapToggleOrbitScaleButton: button)
    }

    @IBAction func changeSizeScaleTapped(_ button: UIButton) {
        print("change size scale")
        delegate?.container(self, didTapToggleSizeScaleButton: button)
    }

    public func disableButtons() {

    }

    public func enableButtons() {

    }
}

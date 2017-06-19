import UIKit

class OnboardingPager: UIView
{
    private let fadedAlpha = CGFloat(0.39)
    
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var pageIndicatorContainer: UIView!
    
    private var pageDots : [UIView] = []
    private var currentPage = 0
    
    func createPageDots(forPageCount pages: Int)
    {
        var previousDot : UIView? = nil
        
        for _ in 0..<pages
        {
            let dot = UIView()
            dot.layer.cornerRadius = 3
            dot.backgroundColor = Style.Color.green
            
            pageIndicatorContainer.addSubview(dot)
            
            dot.snp.makeConstraints { [unowned self] make in
                make.height.width.equalTo(6)
                make.top.equalToSuperview()
                if previousDot == nil
                {
                    make.left.equalToSuperview()
                }
                else
                {
                    make.left.equalTo(previousDot!.snp.right).offset(8)
                    dot.alpha = self.fadedAlpha
                }
            }
            
            pageDots.append(dot)
            
            previousDot = dot
        }
        
        previousDot!.snp.makeConstraints { make in make.right.equalToSuperview() }
    }
    
    func switchPage(to newPage: Int)
    {
        guard newPage != currentPage else { return }
        
        UIView.animate(withDuration: 0.3)
        {
            self.pageDots[self.currentPage].alpha = self.fadedAlpha
            self.pageDots[newPage].alpha = 1
        }
        
        currentPage = newPage;
    }
    
    func clearButtonText()
    {
        nextButton.setTitle(" ", for: .normal)
    }
    
    func hideNextButton()
    {
        nextButton.isEnabled = false
        UIView.animate(withDuration: 0.2)
        {
            self.nextButton.alpha = 0
            self.nextButton.setTitle(" ", for: .normal)
        }
    }
    
    func showNextButton(withText text: String)
    {
        nextButton.isEnabled = true
        UIView.animate(withDuration: 0.2)
        {
            self.nextButton.setTitle(text, for: .normal)
            self.nextButton.alpha = 1
        }
    }
}

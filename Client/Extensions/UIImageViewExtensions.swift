// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared
import Kingfisher

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

public extension UIImageView {

    func setImageAndBackground(forIcon icon: Favicon?, website: URL?, completion: @escaping () -> Void) {
        func finish(bgColor: UIColor?) {
            if let bgColor = bgColor {
                // If the background color is clear, we may decide to set our own background based on the theme.
                let color = bgColor.components.alpha < 0.01 ? UIColor.theme.general.faviconBackground : bgColor
                self.backgroundColor = color
            }
            completion()
        }

        backgroundColor = nil
        let defaults = fallbackFavicon(forUrl: website)

        if let url = website, let bundledIcon = FaviconFetcher.getBundledIcon(forUrl: url) {
            self.image = UIImage(contentsOfFile: bundledIcon.filePath)
            finish(bgColor: bundledIcon.bgcolor)
        } else if let imageURL = URL(string: icon?.url ?? "") {
            ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: imageURL,
                                       limit: ImageLoadingConstants.NoLimitImageSize) { image, error in
                guard error == nil, let image = image else {
                    self.image = defaults.image
                    finish(bgColor: nil)
                    return
                }
                self.image = image
                finish(bgColor: defaults.color)
            }
        } else {
            self.image = defaults.image
            finish(bgColor: nil)
        }
    }

    func setFavicon(forSite site: Site, completion: @escaping () -> Void ) {
        setImageAndBackground(forIcon: site.icon, website: site.tileURL, completion: completion)
    }

   /*
    * If the webpage has low-res favicon, use defaultFavIcon
    */
    func setFaviconOrDefaultIcon(forSite site: Site, completion: @escaping () -> Void ) {
        setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak self] in
            if let image = self?.image, image.size.width < 32 || image.size.height < 32 {
                let defaults = self?.fallbackFavicon(forUrl: site.tileURL)
                self?.image = defaults?.image
                self?.backgroundColor = defaults?.color
            }
            completion()
        }
    }

    private func fallbackFavicon(forUrl url: URL?) -> (image: UIImage, color: UIColor) {
        if let url = url {
            return (FaviconFetcher.letter(forUrl: url), FaviconFetcher.color(forUrl: url))
        } else {
            return (FaviconFetcher.defaultFavicon, .white)
        }
    }

    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

extension UIImage {
    func overlayWith(image: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        image.draw(CGRect(origin: CGPoint.zero, size: image.frame.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

    func overlayWith(image: UIImage) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let modifier: CGFloat = 0.35
        image.draw(in: CGRect(origin: CGPoint(x: 15, y: 16),
                              size: CGSize(width: size.width * modifier,
                                           height: size.height * modifier)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}

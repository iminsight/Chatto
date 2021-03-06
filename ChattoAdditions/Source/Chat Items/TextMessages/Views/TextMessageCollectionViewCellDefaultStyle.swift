/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit
import Chatto

open class TextMessageCollectionViewCellDefaultStyle: TextMessageCollectionViewCellStyleProtocol {
    typealias Class = TextMessageCollectionViewCellDefaultStyle

    public struct BubbleImages {
        let incomingTail: () -> UIImage
        let incomingNoTail: () -> UIImage
        let outgoingTail: () -> UIImage
        let outgoingNoTail: () -> UIImage
        public init(
            incomingTail: @autoclosure @escaping () -> UIImage,
            incomingNoTail: @autoclosure @escaping () -> UIImage,
            outgoingTail: @autoclosure @escaping () -> UIImage,
            outgoingNoTail: @autoclosure @escaping () -> UIImage) {
                self.incomingTail = incomingTail
                self.incomingNoTail = incomingNoTail
                self.outgoingTail = outgoingTail
                self.outgoingNoTail = outgoingNoTail
        }
    }
    
    public struct BubbleStatusImages {
        let sending: () -> UIImage
        let success: () -> UIImage
        
        public init(
            sending: @autoclosure @escaping () -> UIImage,
            success: @autoclosure @escaping () -> UIImage) {
            self.sending = sending
            self.success = success
        }
    }

    public struct TextStyle {
        public let font: () -> UIFont
        public let incomingColor: () -> UIColor
        public let outgoingColor: () -> UIColor
        public let linkTextColor: () -> UIColor
        public let incomingInsets: UIEdgeInsets
        public let outgoingInsets: UIEdgeInsets
        public init(
            font: @autoclosure @escaping () -> UIFont,
            incomingColor: @autoclosure @escaping () -> UIColor,
            outgoingColor: @autoclosure @escaping () -> UIColor,
            linkTextColor: @autoclosure @escaping () -> UIColor,
            incomingInsets: UIEdgeInsets,
            outgoingInsets: UIEdgeInsets) {
            self.font = font
            self.incomingColor = incomingColor
            self.outgoingColor = outgoingColor
            self.linkTextColor = linkTextColor
            self.incomingInsets = incomingInsets
            self.outgoingInsets = outgoingInsets
        }
    }

    public let bubbleImages: BubbleImages
    public let bubbleStatusImages: BubbleStatusImages
    public let textStyle: TextStyle
    public let baseStyle: BaseMessageCollectionViewCellDefaultStyle
    public init (
        bubbleImages: BubbleImages = TextMessageCollectionViewCellDefaultStyle.createDefaultBubbleImages(),
        bubbleStatusImages: BubbleStatusImages = TextMessageCollectionViewCellDefaultStyle.createDefaultBubbleStatusImages(),
        textStyle: TextStyle = TextMessageCollectionViewCellDefaultStyle.createDefaultTextStyle(),
        baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle()) {
            self.bubbleImages = bubbleImages
            self.bubbleStatusImages = bubbleStatusImages
            self.textStyle = textStyle
            self.baseStyle = baseStyle
    }

    lazy private var images: [ImageKey: UIImage] = {
        return [
            .template(isIncoming: true, showsTail: true): self.bubbleImages.incomingTail(),
            .template(isIncoming: true, showsTail: false): self.bubbleImages.incomingNoTail(),
            .template(isIncoming: false, showsTail: true): self.bubbleImages.outgoingTail(),
            .template(isIncoming: false, showsTail: false): self.bubbleImages.outgoingNoTail()
        ]
    }()

    lazy var font: UIFont = textStyle.font()
    lazy var incomingColor: UIColor = textStyle.incomingColor()
    lazy var outgoingColor: UIColor = textStyle.outgoingColor()
    lazy var linkTextColor = textStyle.linkTextColor()

    open func textFont(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont {
        return self.font
    }

    open func linkTextColor(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor {
        return linkTextColor
    }
    
    open func textColor(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor {
        return viewModel.isIncoming ? self.incomingColor : self.outgoingColor
    }

    open func textInsets(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets {
        if shouldShowStatus(viewModel: viewModel) {
            return UIEdgeInsets(top: self.textStyle.outgoingInsets.top,
                                left: self.textStyle.outgoingInsets.left,
                                bottom: self.textStyle.outgoingInsets.bottom,
                                right: self.textStyle.outgoingInsets.right + 10.0 + 5.0)
        }
        return viewModel.isIncoming ? self.textStyle.incomingInsets : self.textStyle.outgoingInsets
    }
    
    open func shouldShowStatus(viewModel: TextMessageViewModelProtocol) -> Bool {
        let isIncoming = viewModel.messageViewModel.isIncoming
        let status = viewModel.messageViewModel.status

        guard isIncoming == false else {
            return false
        }

        switch status {
        case .sending, .success:
            return true
        case .failed:
            return false
        }
    }
    
    open func bubbleStatusImage(viewModel: TextMessageViewModelProtocol) -> UIImage? {
        guard viewModel.isIncoming == false else {
            return nil
        }
        
        switch viewModel.status {
        case .sending:
            return bubbleStatusImages.sending()
        case .success:
            return bubbleStatusImages.success()
        case .failed:
            return nil
        }
    }

    open func bubbleImageBorder(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }

    open func bubbleImage(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage {
        let key = ImageKey.normal(isIncoming: viewModel.isIncoming, status: viewModel.status, showsTail: viewModel.decorationAttributes.isShowingTail, isSelected: isSelected)

        if let image = self.images[key] {
            return image
        } else {
            let templateKey = ImageKey.template(isIncoming: viewModel.isIncoming, showsTail: viewModel.decorationAttributes.isShowingTail)
            if let image = self.images[templateKey] {
                let image = self.createImage(templateImage: image, isIncoming: viewModel.isIncoming, status: viewModel.status, isSelected: isSelected)
                self.images[key] = image
                return image
            }
        }

        assert(false, "coulnd't find image for this status. ImageKey: \(key)")
        return UIImage()
    }

    open func createImage(templateImage image: UIImage, isIncoming: Bool, status: MessageViewModelStatus, isSelected: Bool) -> UIImage {
        var color = isIncoming ? self.baseStyle.baseColorIncoming : self.baseStyle.baseColorOutgoing

        switch status {
        case .success:
            break
        case .failed, .sending:
            color = color.bma_blendWithColor(UIColor.white.withAlphaComponent(0.70))
        }

        if isSelected {
            color = color.bma_blendWithColor(UIColor.black.withAlphaComponent(0.10))
        }

        return image.bma_tintWithColor(color)
    }

    private enum ImageKey: Hashable {
        case template(isIncoming: Bool, showsTail: Bool)
        case normal(isIncoming: Bool, status: MessageViewModelStatus, showsTail: Bool, isSelected: Bool)
    }
}

public extension TextMessageCollectionViewCellDefaultStyle { // Default values

    static func createDefaultBubbleImages() -> BubbleImages {
        return BubbleImages(
            incomingTail: UIImage(named: "bubble-incoming-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            incomingNoTail: UIImage(named: "bubble-incoming", in: Bundle(for: Class.self), compatibleWith: nil)!,
            outgoingTail: UIImage(named: "bubble-outgoing-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            outgoingNoTail: UIImage(named: "bubble-outgoing", in: Bundle(for: Class.self), compatibleWith: nil)!
        )
    }

    static func createDefaultBubbleStatusImages() -> BubbleStatusImages {
        return BubbleStatusImages(
            sending: UIImage(named: "text-status-sending", in: Bundle(for: Class.self), compatibleWith: nil)!,
            success: UIImage(named: "text-status-success", in: Bundle(for: Class.self), compatibleWith: nil)!
        )
    }

    static func createDefaultTextStyle() -> TextStyle {
        return TextStyle(
            font: UIFont.systemFont(ofSize: 16),
            incomingColor: UIColor.black,
            outgoingColor: UIColor.white,
            linkTextColor: UIColor.blue,
            incomingInsets: UIEdgeInsets(top: 10, left: 19, bottom: 10, right: 15),
            outgoingInsets: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 19)
        )
    }
}

//
//  ImageViewTapAction.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Foundation

public enum ImageViewTapAction {
    case openPhotoViewer
    case custom(() -> Void)
	case none
}

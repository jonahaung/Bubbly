//
//  BubbleColor.swift
//  UI
//
//  Created by Aung Ko Min on 16/2/25.
//

import SwiftUI
import XUI

public enum BubbleColor: String, Sendable, Hashable, CaseIterable, Codable, Identifiable {

	case `default`, whatsApp, skyBlue, bluePink, softLilac
	case mistyRose, paleTurquoise, mintCream, warmBeige, aquaBlue, purple, rose, yellow, green, blue

	public var id: String {
		rawValue
	}
	public var value: Color {
		return BubbleColor.colorMap[self] ?? Color.gray
	}
	
	private static let colorMap: [BubbleColor: Color] = [
		.default: Color(red: 1.0, green: 0.98, blue: 0.80),
		.whatsApp: Color(red: 0.85, green: 1.0, blue: 0.85),
		.skyBlue: Color(red: 0.807843137254902, green: 0.9019607843137255, blue: 0.9490196078431372),
		.bluePink: Color(red: 1.0, green: 0.86, blue: 0.9),
		.softLilac: Color(red: 0.9019607843137255, green: 0.9019607843137255, blue: 0.9803921568627451),
		.mistyRose: Color(red: 1.0, green: 0.89, blue: 0.88),
		.paleTurquoise: Color(red: 0.8666666666666667, green: 0.9921568627450981, blue: 0.996078431372549),
		.mintCream: Color(red: 0.8784313725490196, green: 0.9372549019607843, blue: 0.8549019607843137),
		.warmBeige: Color(red: 0.9803921568627451, green: 0.8823529411764706, blue: 0.792156862745098),
		.aquaBlue: Color(red: 0.7450980392156863, green: 0.8823529411764706, blue: 0.9019607843137255),
		.purple: Color(red: 0.9098039215686274, green: 0.8823529411764706, blue: 0.9607843137254902),
		.rose: Color(red: 0.9882352941176471, green: 0.8823529411764706, blue: 0.8941176470588236),
		.yellow: Color(red: 0.9882352941176471, green: 0.9568627450980393, blue: 0.8666666666666667),
		.green: Color(red: 0.8666666666666667, green: 0.9176470588235294, blue: 0.9294117647058824),
		.blue: Color(red: 0.8549019607843137, green: 0.9176470588235294, blue: 0.9647058823529412)
	]
}

extension BubbleColor: XPickable, EmptyRepresentable {
	var color: Color {
		self.value
	}
	public var title: String {
		rawValue
	}
	public static var empty: BubbleColor {
		.default
	}
}

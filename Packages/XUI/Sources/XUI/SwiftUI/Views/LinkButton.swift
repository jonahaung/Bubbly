//
//  ContactLinkButton.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 1/4/23.
//

import SwiftUI

public struct LinkButton<Label: View>: View {

    public enum LinkType {
        case phoneCall(String)
        case sms(String)
        case email(String)
        case whatsapp(phoneNumber: String, message: String)
        case url(String)
        case appleMap(lattitude: Double, longitude: Double)
        case appSettings
    }

    private let linkType: LinkType
    @ViewBuilder private var label: () -> Label

    public init(_ linkType: LinkType, _ label: @escaping () -> Label) {
        self.linkType = linkType
        self.label = label
    }

    @ViewBuilder
    public var body: some View {
        switch linkType {
        case .phoneCall(let phoneNumber):
            if let url = URL(string: "tel://\(phoneNumber.withoutSpacesAndNewLines)") {
                Link(destination: url, label: label)
            }
        case .sms(let phoneNumber):
            if let url = URL(string: "sms://\(phoneNumber.withoutSpacesAndNewLines)") {
                Link(destination: url, label: label)
            }
        case .email(let email):
            if let url = URL(string: "mailto:\(email.withoutSpacesAndNewLines)") {
                Link(destination: url, label: label)
            }
        case .url(let urlString):
            if let url = URL(string: urlString) {
                Link(destination: url, label: label)
            }
        case .whatsapp(let phoneNumber, let text):
            whatsappButton(phone: phoneNumber, msg: text)
        case .appleMap(let lattitide, let longitude):
            if let url = URL(string: "maps://?saddr=&daddr=\(lattitide),\(longitude)") {
                Link(destination: url, label: label)
            }
        case .appSettings:
            Link(destination: URL(string: UIApplication.openSettingsURLString)!, label: label)
        }
    }

    @ViewBuilder
    private func whatsappButton(phone: String, msg: String) -> some View {
        let url: URL? = {
            let urlWhats = "whatsapp://send?phone=\(phone.withoutSpacesAndNewLines)&text=\(msg)"
            var characterSet = CharacterSet.urlQueryAllowed
            characterSet.insert(charactersIn: "?&")
            guard let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: characterSet),
                  let url = URL(string: urlString) else {
                return nil
            }
            return url
        }()
        if let url {
            Link(destination: url, label: label)
        }
    }
}

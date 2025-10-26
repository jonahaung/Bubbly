//
//  DisplayLink.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/10/25.
//

import UIKit

class DisplayLink {

	enum State {
		case inactive
		case running
	}
    private var displayLink: CADisplayLink!
    private var startTime: CFTimeInterval = CACurrentMediaTime()
	private var state = State.inactive
	private let interval: CFTimeInterval = 2

    var displayLinkUpdated: ((_ timeElapsed: Int) -> Void)?

    func startDisplayLink() {
		if state == .running {
			releaseDisplayLink()
		}
		state = .running
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        startTime = CACurrentMediaTime()
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
    }

    func releaseDisplayLink() {
        displayLink.remove(from: .main, forMode: RunLoop.Mode.common)
		startTime = 0
		state = .inactive
    }

    @objc private func update() {
        guard let closure = displayLinkUpdated else { return }
        let elapsedTime: CFTimeInterval = CACurrentMediaTime() - startTime
		if elapsedTime > interval {
			releaseDisplayLink()
			closure(Int(elapsedTime))
		}
    }

}

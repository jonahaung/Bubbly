//
//  SoundEffect 2.swift
//  Core
//
//  Created by Aung Ko Min on 10/3/26.
//

import Foundation

public enum Sound: String, CaseIterable, Sendable {

    case beep
    case biip
    case boop
    case brush

    case chime
    case chimeFalling = "chime.falling"
    case chimeFlat = "chime.flat"
    case chimeRising = "chime.rising"

    case detach
    case dial

    case drip
    case dripFalling = "drip.falling"
    case dripFlat = "drip.flat"
    case dripRising = "drip.rising"

    case glass

    case latch1
    case latch2
    case latch3
    case latch4

    case lock1
    case lock2
    case lock3
    case lock4

    case notFound = "notfound"

    case pick
    case pickFalling = "pick.falling"
    case pickFlat = "pick.flat"
    case pickRising = "pick.rising"

    case ping
    case plop
    case pluck
    case pong

    case pop1
    case pop2
    case pop3
    case pop4
    case pop5

    case reel
    case reelFalling = "reel.falling"
    case reelFlat = "reel.flat"
    case reelRising = "reel.rising"

    case shake
    case snap

    case sparkle
    case sparkleFalling = "sparkle.falling"
    case sparkleFlat = "sparkle.flat"
    case sparkleRising = "sparkle.rising"

    case swipe
    case swish

    case tick
    case tink
    case tock

    case whop
    case wip

    case zing
}
public extension Sound {
	var filename: String {
		rawValue + ".m4a"
	}
}

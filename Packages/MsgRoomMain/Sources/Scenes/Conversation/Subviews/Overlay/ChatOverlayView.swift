//
//  ChatOverlayView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import UIKit
import XUI

struct ChatOverlayView: View {

	let item: ChatOverlayView.Item
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.msgCellActions) private var msgCellActions
	@State private var hasViewAppeared = false

	var body: some View {
		ZStack {
			if hasViewAppeared {
				Rectangle().fill(.background.quinary)
					.glassEffect(.regular, in: .containerRelative)
					.backgroundExtensionEffect()
					.transition(.blurReplace)
					.onTapGesture {
						manager.presentation.updateFocusedFrame(nil)
					}
			}

			ReactionsBar { reaction in
				msgCellActions?(.onReact(viewModel.msg, reaction))
			}
			.position(
				x: item.frame.midX,
				y: item.frame.minY - (hasViewAppeared ? 15 : -15)
			)
			MsgCell.Content()
				.frame(size: item.frame.size)
				.position(x: item.frame.midX, y: item.frame.midY)

			RoomFocesedOverlayBar()
				.position(x: item.frame.midX, y: item.frame.maxY + 10)
		}
		.statusBarHidden()
		.ignoresSafeArea(.container)
		.onAppear {
			withAnimation(.interactiveSpring.delay(0.2)) {
				hasViewAppeared.toggle()
			}
		}
	}
}

public struct ReactionRotateButton<Label: View>: View {
	let alignment: HorizontalAlignment
	let label: () -> Label
	let action: () -> Void
	@State private var animate = false

	public init(
		_ alignment: HorizontalAlignment,
		action: @escaping () -> Void,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.label = label
		self.action = action
		self.alignment = alignment
	}

	public var body: some View {
		Button {
			withAnimation(
				.interpolatingSpring(
					stiffness: 170,
					damping: 10
				)
			) {
				animate.toggle()
			} completion: {
				withAnimation(.bouncy(extraBounce: 0.4)) {
					animate = false
				} completion: {
					action()
				}
			}
		} label: {
			label()
				.rotationEffect(.degrees(degrees), anchor: anchor)
				.scaleEffect(animate ? 1.8 : 1, anchor: anchor)
				.offset(y: offsetY)
		}
		.buttonStyle(.borderless)
		.sensoryFeedback(.selection, trigger: anchor)
	}

	private var offsetY: CGFloat {
		CGFloat(animate ? alignment == .center ? -10 : -40 : 0)
	}
	private var degrees: Double {
		if animate {
			switch alignment {
			case .leading: return -45
			case .center: return 360
			case .trailing: return 45
			default: return 0
			}
		}
		return 0
	}
	private var anchor: UnitPoint {
		switch alignment {
		case .leading: return .bottomTrailing
		case .center: return .center
		case .trailing: return .bottomLeading
		default: return .center
		}
	}
}

//public struct ReactionJumpButton<Label: View>: View {
//    enum Reaction: CaseIterable {
//        case initial, move, scale
//        var verticalOffset: Double {
//            switch self {
//            case .initial: 0
//            case .move, .scale: -64
//            }
//        }
//
//        var scale: Double {
//            switch self {
//            case .initial: 1
//            case .move, .scale: 2.0
//            }
//        }
//
//        var chromaRotate: Double {
//            switch self {
//            case .initial: 0.0
//            case .move, .scale: 225.0
//            }
//        }
//    }
//
//    let label: () -> Label
//    let action: () -> Void
//    @State private var reactionCount = 0
//
//    public init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
//        self.label = label
//        self.action = action
//    }
//
//    public var body: some View {
//        Button {
//            reactionCount += 1
//            DispatchQueue.delay(1.3) {
//                action()
//            }
//        } label: {
//            label()
//        }
//        //		.sensoryFeedback(.selection, trigger: reactionCount)
//        .phaseAnimator(
//            Reaction.allCases,
//            trigger: reactionCount
//        ) { heartSymbol, jump in
//            heartSymbol
//                .scaleEffect(jump.scale)
//                .offset(y: jump.verticalOffset)
//                .hueRotation(.degrees(jump.chromaRotate))
//        } animation: { jump in
//            switch jump {
//            case .initial: .bouncy(duration: 0.5, extraBounce: 0.25)
//            case .move: .easeInOut(duration: 0.3).delay(0.25)
//            case .scale: .spring(duration: 0.5, bounce: 0.7)
//            }
//        }
//    }
//}

struct RoomFocesedOverlayBar: View {
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(MsgCellViewModel.self) private var item
	private let iconStyle = SystemImageWithShape.IconStyle.circle(.plain)
	@State private var showInfo = false
	var body: some View {
		HStack(spacing: 0) {
			ReactionRotateButton(.center) {
				Task {
					let msg = item.msg
					try? await Socket.shared.send(.deleteMsg(rMsg: .init(msg)), conversation: manager.conversation)
					manager.presentation.updateFocusedFrame(nil)
				}
			} label: {
				SystemImageWithShape(.trashFill, iconStyle)
			}
			ReactionRotateButton(.leading) {} label: {
				SystemImageWithShape(.arrowshapeTurnUpLeftFill, iconStyle)
			}

			ReactionRotateButton(.trailing) {} label: {
				SystemImageWithShape(.arrowshapeTurnUpRightFill, iconStyle)
			}
			ReactionRotateButton(.center) {
				UIPasteboard.general.string = item.msg.text
			} label: {
				SystemImageWithShape(.squareFilledOnSquare, iconStyle)
			}
			ReactionRotateButton(.center) {
				showInfo = true
			} label: {
				SystemImageWithShape(.ellipsis, iconStyle)
			}.padding(.leading)
		}
		.sheet(isPresented: $showInfo) {
			NavigationStack {
				VStack {
					TextEditor(text: .constant(item.msg.preetyPrinted))
						.textSelection(.enabled)
						.font(.footnote.monospaced())
						.scrollIndicators(.hidden)
				}
				.padding()
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button(role: .close) {
							showInfo = false
						}
					}
				}
			}
		}
	}
}


//
//  FolderExplorer.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 20/10/25.
//

import SwiftUI
import XUI

public struct FolderExplorer: View {
	public init() {}
	public var body: some View {
		List {
			NavigationLink {
				FolderListView(folder: .current)
			} label: {
				Text("Current")
			}
			if let folder = Folder.documents {
				NavigationLink {
					FolderListView(folder: folder)
				} label: {
					Text("Documents")
				}
			}

			NavigationLink {
				FolderListView(folder: .home)
			} label: {
				Text("Home")
			}
			NavigationLink {
				FolderListView(folder: .root)
			} label: {
				Text("Root")
			}
			if let folder = Folder.library {
				NavigationLink {
					FolderListView(folder: folder)
				} label: {
					Text("Libarary")
				}
			}
			NavigationLink {
				FolderListView(folder: .temporary)
			} label: {
				Text("Temporary")
			}
		}
	}
}

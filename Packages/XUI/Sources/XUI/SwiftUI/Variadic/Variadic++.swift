//
//  Variadic++.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 12/6/24.
//

import SwiftUI

private struct ViewSelector: _VariadicView_MultiViewRoot {
    let position: Int
    func body(children: _VariadicView.Children) -> some View {
        children[position]
    }
}

public extension View {
    func selectSubview(_ position: Int) -> some View {
        _VariadicView.Tree(ViewSelector(position: position)) {
            self
        }
    }
}
private struct Helper<Result: View>: _VariadicView_MultiViewRoot {
    var _body: (_VariadicView.Children) -> Result

    func body(children: _VariadicView.Children) -> some View {
        _body(children)
    }
}
public extension View {
    func variadic<R: View>(@ViewBuilder process: @escaping (_VariadicView.Children) -> R) -> some View {
        _VariadicView.Tree(Helper(_body: process), content: { self })
    }
}
public extension View {
    @ViewBuilder
    func intersperse<V: View>(@ViewBuilder _ divider: () -> V) -> some View {
        let el = divider()
        variadic { children in
            if let c = children.first {
                c
                ForEach(children.dropFirst(1)) { child in
                    el
                    child
                }
            }
        }
    }
}

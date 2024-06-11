//
//  ContentView.swift
//  TCAtoMVVMTest
//
//  Created by Jon Duenas on 6/11/24.
//

import SwiftUI
import ComposableArchitecture
import SwiftUINavigation

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var contentFeature = ContentFeature.State()
    }

    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case contentFeature(ContentFeature.Action)
        case didSelectCount(Int)
    }

    @Reducer(state: .equatable)
    enum Path {
        @ReducerCaseIgnored
        case mvvmFeature
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.contentFeature, action: \.contentFeature) {
            ContentFeature()
        }

        Reduce { state, action in
            switch action {
            case .path:
                return .none
            case .contentFeature(.delegate(.didTapMVVMFeature)):
                state.path.append(.mvvmFeature)
                return .none
            case .contentFeature:
                return .none
            case let .didSelectCount(count):
                // If Root should receive count, then how to send back to ContentFeature?
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

@Reducer
struct ContentFeature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action {
        @CasePathable
        enum Delegate {
            case didTapMVVMFeature
        }

        case buttonTapped
        case didSelectCount(Int)
        case delegate(Delegate)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .buttonTapped:
                return .send(.delegate(.didTapMVVMFeature))
            case .didSelectCount(let count):
                state.count = count
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

@MainActor
@Observable
final class ViewModel: HashableObject {
    var count: Int = 0

    var onButtonTapped: ((Int) -> Void)?

    func buttonTapped() {
        onButtonTapped?(count)
    }
}

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ContentView(store: store.scope(state: \.contentFeature, action: \.contentFeature))
        } destination: { store in
            switch store.case {
            case .mvvmFeature:
                let vm = ViewModel()
                let _ = vm.onButtonTapped = { [weak store = self.store] count in
                    // Send to RootFeature Store? How to get back into ContentFeature?
                    store?.send(.didSelectCount(count))
                }
                MVVMFeatureView(viewModel: vm)
            }
        }
    }
}

struct ContentView: View {
    let store: StoreOf<ContentFeature>

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Store Count: \(store.count)")
            Button("Push MVVM Feature") {
                store.send(.buttonTapped)
            }
        }
        .padding()
    }
}

struct MVVMFeatureView: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        VStack {
            Text("MVVM World")
            Text("ViewModel Count: \(viewModel.count)")
            Stepper("Counter", value: $viewModel.count)
                .labelsHidden()
            Button("Send data back to TCA") {
                viewModel.buttonTapped()
            }
        }
    }
}

#Preview {
    ContentView(store: Store(initialState: ContentFeature.State(), reducer: ContentFeature.init))
}

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
struct ContentFeature {
    @ObservableState
    public struct State: Equatable {
        var path = StackState<Path.State>()
        var count = 0
    }

    public enum Action{
        case path(StackAction<Path.State, Path.Action>)
        case buttonTapped
        case pushMVVMFeature(ViewModel)
        case didSelectCount(Int)
    }

    @Reducer(state: .equatable)
    public enum Path {
        @ReducerCaseIgnored
        case mvvmFeature(ViewModel)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .path:
                return .none
            case .buttonTapped:
                return .run { @MainActor send in
                    let viewModel = ViewModel()
                    let (stream, continuation) = AsyncStream.makeStream(of: Int.self)

                    viewModel.onButtonTapped = { count in
                        continuation.yield(count)
                    }

                    send(.pushMVVMFeature(viewModel))

                    for await count in stream {
                        send(.didSelectCount(count))
                    }
                    print("Stream cancelled")
                }
            case .pushMVVMFeature(let viewModel):
                state.path.append(.mvvmFeature(viewModel))
                return .none
            case .didSelectCount(let count):
                state.count = count
                state.path.removeLast()
                return .none
            }
        }
        .forEach(\.path, action: \.path)
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

struct ContentView: View {
    @Bindable var store: StoreOf<ContentFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
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
        } destination: { store in
            switch store.case {
            case .mvvmFeature(let viewModel):
                MVVMFeatureView(viewModel: viewModel)
            }
        }
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

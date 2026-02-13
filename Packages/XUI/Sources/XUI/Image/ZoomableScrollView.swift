import Combine
import SwiftUI

public struct ZoomableScrollView<Content: View>: View {
	private let content: Content
	@State private var doubleTap = PassthroughSubject<Void, Never>()

	public init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	public var body: some View {
		ZoomableScrollViewImpl(content: content, doubleTap: doubleTap.eraseToAnyPublisher())
			.onTapGesture(count: 2) {
				doubleTap.send()
			}
	}
}

private struct ZoomableScrollViewImpl<Content: View>: UIViewControllerRepresentable {
	let content: Content
	let doubleTap: AnyPublisher<Void, Never>

	func makeUIViewController(context: Context) -> ZoomableScrollViewController {
		ZoomableScrollViewController(coordinator: context.coordinator, doubleTap: doubleTap)
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(hostingController: UIHostingController(rootView: content))
	}

	func updateUIViewController(_ viewController: ZoomableScrollViewController,
	                            context _: Context)
	{
		viewController.update(content: content, doubleTap: doubleTap)
	}

	// MARK: - Coordinator

	class Coordinator: NSObject, UIScrollViewDelegate {
		let hostingController: UIHostingController<Content>

		init(hostingController: UIHostingController<Content>) {
			self.hostingController = hostingController
		}
	}
}

// MARK: - ZoomableScrollViewController

extension ZoomableScrollViewImpl {
	class ZoomableScrollViewController: UIViewController, UIScrollViewDelegate {
		let coordinator: Coordinator

		private let scrollView: UIScrollView = {
			$0.maximumZoomScale = 20
			$0.minimumZoomScale = 0.7
			$0.bouncesZoom = true
			$0.showsHorizontalScrollIndicator = false
			$0.showsVerticalScrollIndicator = false
			$0.clipsToBounds = false
			$0.backgroundColor = .clear
			return $0
		}(UIScrollView())

		private var doubleTapCancellable: Cancellable?
		private var hostedView: UIView {
			coordinator.hostingController.view!
		}

		private var contentSizeConstraints: [NSLayoutConstraint] = [] {
			willSet { NSLayoutConstraint.deactivate(contentSizeConstraints) }
			didSet { NSLayoutConstraint.activate(contentSizeConstraints) }
		}

		@available(*, unavailable)
		required init?(coder _: NSCoder) {
			fatalError()
		}

		init(coordinator: Coordinator, doubleTap: AnyPublisher<Void, Never>) {
			self.coordinator = coordinator
			super.init(nibName: nil, bundle: nil)
			doubleTapCancellable = doubleTap.debounce(for: 0.2, scheduler: RunLoop.main)
				.sink { [unowned self] in handleDoubleTap() }
		}

		override func loadView() {
			view = scrollView
		}

		override func viewDidLoad() {
			super.viewDidLoad()

			hostedView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(hostedView)

			NSLayoutConstraint.activate([
				hostedView.leadingAnchor
					.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
				hostedView.trailingAnchor
					.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
				hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
				hostedView.bottomAnchor
					.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
			])

			scrollView.delegate = self
		}

		deinit {
			log("Deinit")
		}

		func update(content: Content, doubleTap: AnyPublisher<Void, Never>) {
			coordinator.hostingController.rootView = content
			scrollView.setNeedsUpdateConstraints()
			doubleTapCancellable = doubleTap.sink { [unowned self] in handleDoubleTap() }
		}

		func handleDoubleTap() {
			scrollView.setZoomScale(
				scrollView.zoomScale > 1 ? scrollView.minimumZoomScale : 2,
				animated: true
			)
		}

		override func updateViewConstraints() {
			super.updateViewConstraints()
			let hostedContentSize = coordinator.hostingController.sizeThatFits(in: view.bounds.size)
			contentSizeConstraints = [
				hostedView.widthAnchor.constraint(equalToConstant: hostedContentSize.width),
				hostedView.heightAnchor.constraint(equalToConstant: hostedContentSize.height),
			]
		}

		override func viewDidAppear(_: Bool) {
			scrollView.zoom(to: hostedView.bounds, animated: false)
		}

		override func viewDidLayoutSubviews() {
			super.viewDidLayoutSubviews()

			let hostedContentSize = coordinator.hostingController.sizeThatFits(in: view.bounds.size)
			scrollView.minimumZoomScale = min(
				scrollView.bounds.width / hostedContentSize.width,
				scrollView.bounds.height / hostedContentSize.height
			)
		}

		override func viewWillTransition(to _: CGSize,
		                                 with coordinator: UIViewControllerTransitionCoordinator)
		{
			coordinator.animate(alongsideTransition: { _ in
				self.scrollView.zoom(to: self.hostedView.bounds, animated: false)
			})
		}

		func viewForZooming(in _: UIScrollView) -> UIView? {
			hostedView
		}
	}
}

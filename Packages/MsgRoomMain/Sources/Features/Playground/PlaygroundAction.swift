enum PlaygroundAction {
	case setLoading(Bool)
	case setError(String?)
	case applySnapshot(PlaygroundSnapshot)
}

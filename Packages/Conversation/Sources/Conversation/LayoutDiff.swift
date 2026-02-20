struct LayoutDiff {

	let insertedTop: [String]
	let insertedBottom: [String]
	let updated: [String]
	let removed: [String]
}

func computeDiff(
	old: [String],
	new: [String]
) -> LayoutDiff {

	let oldSet = Set(old)
	let newSet = Set(new)

	let removed = old.filter { !newSet.contains($0) }
	let inserted = new.filter { !oldSet.contains($0) }

	let insertedTop = new.prefix(inserted.count)
		.filter { inserted.contains($0) }

	let insertedBottom = new.suffix(inserted.count)
		.filter { inserted.contains($0) }

	let updated = new.filter { id in
		old.contains(id) && !removed.contains(id)
	}

	return LayoutDiff(
		insertedTop: Array(insertedTop),
		insertedBottom: Array(insertedBottom),
		updated: updated,
		removed: removed
	)
}
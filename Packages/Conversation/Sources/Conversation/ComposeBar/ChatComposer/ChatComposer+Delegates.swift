import MediaPicker

extension ChatComposer: InputTextDelegate {
    func inputText(_: InputText, didInsertLinks links: [ExtractedLink]) {
        queue.addOperation { [weak self] in
            await self?.parseLinks(links: links)
        }
    }

    func inputText(_: InputText, didBeganEditing _: String) {
        state.menuIsOpened = false
    }

    func inputText(_: InputText, didEndEditing _: String) {
        state.attachments = []
    }

    func inputText(_: InputText, didInsert _: String) {}
}

extension ChatComposer: PhotoPickerManagerDelegate {
    func photoPickerManager(
        _: PhotoPickerManager,
        didSelectImages images: [SelectedImage]
    ) {
        queue.addOperation { [weak self] in
            await self?.parseImages(selectedImages: images)
        }
    }
}

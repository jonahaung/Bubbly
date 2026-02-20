import Database
import MediaPicker

enum UserProfileIntent {
	case appear
	case refreshRemote
	case editName(String)
	case setPickedPhoto(PickedPhoto?)
	case resetChanges
	case saveChanges
	case signOut
	case removeDisplayName
}

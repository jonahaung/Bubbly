import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ async -> HTTPStatus in
        .ok
    }

    app.get("v1", "profile-photos", ":userID", use: ProfilePhotoController.show)

    let authenticated = app.grouped(FirebaseAuthenticationMiddleware())
    try authenticated.register(collection: ContactsController())
    try authenticated.register(collection: ProfileController())
    try authenticated.register(collection: GroupsController())
}

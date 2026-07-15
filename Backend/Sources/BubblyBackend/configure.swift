import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

func configure(_ app: Application) async throws {
    let configuration = try AppConfiguration.load(environment: app.environment)
    app.bubblyConfiguration = configuration
    app.firebaseTokenVerifier = FirebaseTokenVerifier(projectID: configuration.firebaseProjectID)
    app.routes.defaultMaxBodySize = "2mb"

    let databaseConfiguration = try makeDatabaseConfiguration(environment: app.environment)
    app.databases.use(.postgres(configuration: databaseConfiguration), as: .psql)
    app.migrations.add(CreateContact())

    if Environment.get("AUTO_MIGRATE")?.lowercased() == "true" {
        try await app.autoMigrate()
    }

    try routes(app)
}

private func makeDatabaseConfiguration(environment: Environment) throws -> SQLPostgresConfiguration {
    if let databaseURL = Environment.get("DATABASE_URL"), !databaseURL.isEmpty {
        return try SQLPostgresConfiguration(url: databaseURL)
    }

    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "bubbly"
    let password = Environment.get("DATABASE_PASSWORD") ?? "bubbly"
    let database = Environment.get("DATABASE_NAME") ?? "bubbly"
    let tlsConfiguration: TLSConfiguration =
        if environment == .production {
            .makeClientConfiguration()
        } else {
            .makeClientConfiguration()
        }

    return SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: environment == .production ? .require(try .init(configuration: tlsConfiguration)) : .disable
    )
}

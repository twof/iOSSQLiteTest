// Repositories basically a means to retrieve data which should be ignorant of the means of retrieving the data
// There are datasoures, and models
// Each model needs to have a way to run crud operations on each datasource
// Could also seperate the models and the means of querying them
import Foundation
import Service
import Squeal

protocol IDType: Codable, Equatable {  }

extension Int: IDType { }
extension String: IDType { }
extension UUID: IDType { }
extension Int64: IDType {  }

extension Optional: IDType where Wrapped: IDType { }

protocol Model: Encodable {
    associatedtype ID: IDType
    var id: ID { get }
}

protocol SQLiteModel: Model where ID == Int64? {
    init(row: Statement)
    static var modelName: String { get }
}

extension SQLiteModel {
    static var modelName: String {
        return String(describing: Self.self).lowercased()
    }
}

protocol Location { }

struct MockLocation: Location { }
struct MemoryLocation: Location { }
struct PersistenceLocation: Location { }
struct RemoteLocation: Location { }

protocol DataSource: Service {  }

protocol CrudDataSource: DataSource {
    associatedtype ModelType: Model
    associatedtype SourceLocation: Location

    func read(id: ModelType.ID) throws -> ModelType?
    func readAll() throws -> [ModelType]
    func create(model: ModelType) throws -> ModelType.ID
    func update(model: ModelType) throws -> ModelType?
    func delete(_ id: ModelType.ID) throws -> ModelType?
}

protocol SQLiteCrudDataSource: CrudDataSource where ModelType: SQLiteModel {
    var database: Database { get set }
}

extension Encodable {
    func asDictionary() throws -> [String: Bindable?] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Bindable?] else {
            throw NSError()
        }
        return dictionary
    }
}

extension Database {
    func selectAll<M: SQLiteModel>(modelType: M.Type) throws -> [M] {
        return try selectFrom(
            modelType.modelName,
            block: M.init
        )
    }

    func select<M: SQLiteModel>(modelType: M.Type, withId id: M.ID.WrappedType) throws -> M? {
        return try selectFrom(M.modelName, whereExpr: "id=\(id)", block: M.init).first
    }

    func create<M: SQLiteModel>(model: M) throws -> M.ID.WrappedType {
        return try insertInto(M.modelName, values: model.asDictionary()) as! M.ID
    }

    func delete<M: SQLiteModel>(modelType: M.Type, withId id: M.ID.WrappedType) throws -> M? {
        let model = try select(modelType: modelType, withId: id)
        try deleteFrom(M.modelName, rowIds: [id])
        return model
    }
}

extension SQLiteCrudDataSource where ModelType: SQLiteModel {
    func read(id: ModelType.ID) throws -> ModelType? {
        return try self.database.select(modelType: ModelType.self, withId: id)
    }

    func readAll() throws -> [ModelType] {
        return try self.database.selectAll(modelType: ModelType.self)
    }

    func create(model: ModelType) throws -> ModelType.ID {
        return try self.database.create(model: model)
    }

    func update(model: ModelType) throws -> ModelType? {
        _ = try delete(model.id)
        let id = try create(model: model)
        return try read(id: id)
    }

    func delete(_ id: ModelType.ID) throws -> ModelType? {
        return try self.database.delete(modelType: ModelType.self, withId: id)
    }
}

public final class Repository: Container {
    public var config: Config

    public var environment: Environment

    public var services: Services

    public var serviceCache: ServiceCache

    public convenience init(
        config: Config = .init(),
        environment: Environment = .development,
        services: Services = .init()
    ) throws {
        self.init(config, environment, services)
    }

    /// Internal initializer. Creates an `Application` without booting providers.
    internal init(_ config: Config, _ environment: Environment, _ services: Services) {
        self.config = config
        self.environment = environment
        self.services = services
        self.serviceCache = .init()
    }

    func register<S: Service>(_ dataSource: S) {
        self.services.register(dataSource)
    }

    func get<S: Service>(_ dataSource: S.Type) throws -> S {
        return try self.make(dataSource)
    }
}

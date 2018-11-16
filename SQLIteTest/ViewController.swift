import UIKit
import Squeal

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            let db = Database()

            // Create:
            try db.createTable("contacts", definitions: [
                "id INTEGER PRIMARY KEY",
                "name TEXT",
                "email TEXT NOT NULL"
                ])

            // Insert:
            let contactId = try db.insertInto(
                "contacts",
                values: [
                    "name": "Amelia Grey",
                    "email": "amelia@gastrobot.xyz"
                ]
            )
            print(contactId)

            // Select:
            struct Contact {
                let id:Int
                let name:String?
                let email:String

                init(row: Statement) throws {
                    id = row.intValue("id") ?? 0
                    name = row.stringValue("name")
                    email = row.stringValue("email") ?? ""
                }
            }


            let contacts:[Contact] = try db.selectFrom(
                "contacts",
                whereExpr:"name IS NOT NULL",
                block: Contact.init
            )
            print(contacts)

            // Count:
            let numberOfContacts = try db.countFrom("contacts")
            print(numberOfContacts)
        } catch {
            print(error)
        }

//        struct Dog: SQLiteModel {
//            var id: Int64?
//            let name: String
//            let age: Int
//        }
//
////        struct MockDataSource
//
//        let mockDataSource = DataSource<Dog, MockLocation>(
//            read: { (id) -> Dog? in
//                return Dog(id: id, name: "Rex", age: 10)
//            }, readAll: { () -> [Dog] in
//                return [Dog(id: 0, name: "Rex", age: 10), Dog(id: 1, name: "Cat", age: 20), Dog(id: 2, name: "Jamie", age: 5)]
//            }, create: { (dog) -> Dog in
//                return dog
//            }, update: { (dog) -> Dog? in
//                return dog
//            }, delete: { (id) -> Dog? in
//                return Dog(id: id, name: "Rex", age: 10)
//            }
//        )
//
//        let sqliteDataSource = DataSource<Dog, PersistenceLocation>(
//            read: { (id) -> Dog? in
//
//            }, readAll: { () -> [Dog] in
//                <#code#>
//            }, create: { (<#Dog#>) -> Dog in
//                <#code#>
//            }, update: { (<#Dog#>) -> Dog? in
//                <#code#>
//            }, delete: { (id) -> Dog? in
//
//            }
//        )
//
//        do {
//            let repo = try Repository()
//            repo.register(dataSource: mockDataSource)
//
//            let madeDatasource = try repo.make(DataSource<Dog, MockLocation>.self)
//
//            print(madeDatasource.readAll())
//        } catch {
//            print(error)
//        }
    }
}


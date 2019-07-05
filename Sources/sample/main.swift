
import LibPQ
import Foundation

let conn = try! Connection(connectionInfo: "host=localhost port=5432 dbname=swifttalk_dev connect_timeout=10")
let tables = [
   "downloads",
   "files",
   "gifts",
   "play_progress",
   "sessions",
   "tasks",
   "team_members",
   "users"
]

for table in tables {
    let result = try conn.execute(sql: "select * from \(table) limit 1")
    switch result {
    case .tuples(let t): print(t)
    default: print("Unkown")
    }
}

guard case let .tuples(result) = try conn.execute(sql: "select * from users where github_login=$1 limit 1", params: ["chriseidhof"]) else { fatalError() }
for row in result {
    for col in row.startIndex..<row.endIndex {
        let info = row[info: col]
        switch info.oid {
        case .timestamp:
            print(Date(stringValue: info.value))
        case .uuid:
            print(UUID(stringValue: info.value))
        default: print(info)
        }
        
    }
}

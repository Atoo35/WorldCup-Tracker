import Foundation

struct Team: Decodable, Identifiable {
    let id: String
    let name_en: String
    let name_fa: String
    let flag: String
    let fifa_code: String
    let iso2: String
    let groups: String
}

struct TeamsResponse: Decodable {
    let teams: [Team]
}
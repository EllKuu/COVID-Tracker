//
//  APICaller.swift
//  COVID Tracker
//
//  Created by elliott kung on 2021-06-13.
//

import Foundation

extension DateFormatter{
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
        
    }()
    
    static let prettyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
        
    }()
}

class APICaller {
    static let shared = APICaller()
    
    private init(){
        
    }
    
    private struct Constants{
        static let allStateUrl = URL(string: "https://api.covidtracking.com/v2/states.json")
        static let covidStateDataUrl = "https://api.covidtracking.com/v2/states/ca/daily.json"
    }
    
    enum DataScope {
        case national
        case state(State)
        
    }
    
    public func getSingleDayData(
        for scope: DataScope,
        for date: Date,
        completion: @escaping (Result<SingleDayData, Error>) -> Void
    ){
//        print("in API call")
//        print(scope)
//        print(date)
        
        let dateString = DateFormatter()
        dateString.dateFormat = "YYYY-MM-dd"
        print(dateString.string(from: date))
        let formatDate = dateString.string(from: date)
        
        let urlString: String
        switch scope {
        case .national:
            urlString =  "https://api.covidtracking.com/v2/us/daily/\(formatDate)/simple.json"
        case .state(let state):
            urlString =  "https://api.covidtracking.com/v2/states/\(state.state_code.lowercased())/\(formatDate)/simple.json"
        }
        
        guard let url = URL(string: urlString) else { return }
        print(url)
        
        let task = URLSession.shared.dataTask(with: url){ data, _, error in
            guard let data = data , error == nil else { return }
                
                do {
                    let result = try JSONDecoder().decode(SingleDayCovidDataResponse.self, from: data)
                    print(result.data)
                    let caseTotal = result.data.cases?.total ?? 0
                    let icuTotal = result.data.outcomes?.hospitalized?.in_icu?.currently ?? 0
                    let ventilatorTotal = result.data.outcomes?.hospitalized?.on_ventilator?.currently ?? 0
                    let deathTotal = result.data.outcomes?.death?.total ?? 0
                    
                    let singleDayData = SingleDayData(total: caseTotal, icu: icuTotal, ventilator: ventilatorTotal, deaths: deathTotal)
                    
                    completion(.success(singleDayData))
                   
                }catch{
                    completion(.failure(error))
                }
            }
        task.resume()
            
    }
    
    public func getCovidData(
        for scope: DataScope,
        completion: @escaping (Result<[DayData], Error>) -> Void
    ){
        let urlString: String
        switch scope {
        case .national:
            urlString = "https://api.covidtracking.com/v2/us/daily.json"
        case .state(let state):
            urlString =  "https://api.covidtracking.com/v2/states/\(state.state_code.lowercased())/daily.json"
        }
        
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data , error == nil else { return }
            
            do {
                let result = try JSONDecoder().decode(CovidDataResponse.self, from: data)
                result.data.forEach { model in
                    let models: [DayData] =  result.data.compactMap{
                        guard let value = $0.cases?.total.value,
                                 let date = DateFormatter.dayFormatter.date(from: $0.date) else {
                            return nil
                        }
                        return DayData(
                            date: date,
                            count: value
                        )
                    }
                    completion(.success(models))
                }
            }
            catch{
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    public func getStateList(completion: @escaping (Result<[State], Error>) -> Void) {
        guard let url = Constants.allStateUrl else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data , error == nil else { return }
            
            do {
                let result = try JSONDecoder().decode(StateListResponse.self, from: data)
                let states = result.data
                completion(.success(states))
            }
            catch{
                completion(.failure(error))
            }
        }
        task.resume()
}
    
}

// MARK: Models


// MARK: State Codes
struct StateListResponse: Codable{
    let data: [State]
}

struct State: Codable {
    let name: String
    let state_code: String
}

// MARK: Historic data

struct CovidDataResponse: Codable{
    let data: [CovidDayData]
}

struct CovidDayData: Codable {
    let cases: CovidCases?
    let date: String
}

struct CovidCases: Codable {
    let total: TotalCases
}

struct TotalCases: Codable {
    let value: Int?
}

struct DayData{
    let date: Date
    let count: Int
}

// MARK: Single Day Data

struct SingleDayCovidDataResponse: Codable{
    let data: SingleDayCovidData
}

struct SingleDayCovidData: Codable{
    let cases: SingleDayTotalCovidCases?
    let outcomes: SingleDayOutcomes?
}

struct SingleDayTotalCovidCases: Codable{
    let total: Int?
    let confirmed: Int?
    let probable: Int?
}

struct SingleDayOutcomes: Codable{
    let hospitalized: SingleDayHospitilizations?
    let death: SingleDayDeaths?

}

struct SingleDayHospitilizations: Codable{
    let in_icu: SingleDayICU?
    let on_ventilator: SingleDayVentilator?
}

struct SingleDayICU: Codable{
    let currently: Int?
}

struct SingleDayVentilator: Codable{
    let currently: Int?
}

struct SingleDayDeaths: Codable{
    let total: Int?
}

struct SingleDayData{
    var total: Int
    var icu: Int
    var ventilator: Int
    var deaths: Int
}

//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "5c5cb96ec31d2899ea6dc1650e0753eb"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case getSession
        case validateVieWebSite
        case logout
        case getFavoriteList
        case markAsFavorite
        case searchMovie(String)
        case addToWatchlist
        case downloadPoster(String)
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken:
                return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .getSession:
                return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .validateVieWebSite:
                return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout:
                return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavoriteList:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .searchMovie(let query):
                return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .markAsFavorite:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .addToWatchlist:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .downloadPoster(let posterPath):
                return "https://image.tmdb.org/t/p/w500/" + posterPath
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    class func taskForGetRequest<ResponseType:Codable>(url:URL, response:ResponseType.Type, completionHandler: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do {
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject, nil)
                }
            } catch {
                do {
                    let errorObject = try JSONDecoder().decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(nil, errorObject)
                    }
                } catch{
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    class func taskForPostRequest<ResponseType:Decodable, RequestType:Encodable>(url:URL, responseType:ResponseType.Type, body:RequestType, completionHandler: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: url)
        request.httpMethod = "Post"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do {
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject, nil)
                }
            } catch {
                do {
                    let errorObject = try JSONDecoder().decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                    completionHandler(nil, errorObject)
                        }
                } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                   }
                }
            }
        }
        task.resume()
        return task
    }
    class func getRequestToken(completionHandler: @escaping (Bool, Error?) -> Void) -> URLSessionTask {
      let task = TMDBClient.taskForGetRequest(url: TMDBClient.Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let respose = response {
                TMDBClient.Auth.requestToken = respose.requestToken
                completionHandler(true, nil)
            }
            else {
                completionHandler(false, nil)
            }
        }
        return task
    }
    class func login(userName:String, password:String, completionHandler: @escaping (Bool, Error?) -> Void) -> URLSessionTask{
//        var request = URLRequest(url: TMDBClient.Endpoints.login.url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LoginRequest(username: userName, password: password, requestToken: TMDBClient.Auth.requestToken)
       let task = TMDBClient.taskForPostRequest(url: TMDBClient.Endpoints.login.url, responseType: RequestTokenResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
       }
        return task
    }
    class func getSessionId(completionHandler: @escaping (Bool, Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: TMDBClient.Endpoints.getSession.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PostSession(requestToken: Auth.requestToken)
        let task = TMDBClient.taskForPostRequest(url: TMDBClient.Endpoints.getSession.url, responseType: SessionResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
        return task
    }
    class func logout(completionHandler: @escaping () -> Void) {
        var request = URLRequest(url: TMDBClient.Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("applicatin/json", forHTTPHeaderField: "Content-Type")
        let body = LogoutRequest(sessionId: Auth.sessionId)
        request.httpBody = try! JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
           Auth.requestToken = ""
            Auth.sessionId = ""
            completionHandler()
        }
        task.resume()
    }
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
        let task = TMDBClient.taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
        return task
    }
    class func getFavoriteList(completionHandler: @escaping ([Movie], Error?) -> Void) -> URLSessionTask{
        let task = TMDBClient.taskForGetRequest(url: TMDBClient.Endpoints.getFavoriteList.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completionHandler(response.results, nil)
            } else {
                completionHandler([], error)
            }
        }
        return task
    }
    class func searchMovie(query:String, completionHandler: @escaping ([Movie],Error?) -> Void) -> URLSessionTask {
        let task = TMDBClient.taskForGetRequest(url: TMDBClient.Endpoints.searchMovie(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
               completionHandler(response.results, nil)
            } else {
                completionHandler([], error)
            }
        }
        return task
    }
    class func markFavoriteMovie(mediaId: Int, isFavorite:Bool, completionHandler: @escaping (Bool, Error?) -> Void) -> URLSessionTask{
        let body = MarkFavorite(mediaType: "movie", mediaId: mediaId, favorite: isFavorite)
        let task = TMDBClient.taskForPostRequest(url: TMDBClient.Endpoints.markAsFavorite.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completionHandler(false, error)
                print(error!)
            }
        }
        return task
    }
    class func addToWatchlist(mediaId: Int, isWatch:Bool, completionHandler: @escaping (Bool, Error?) -> Void) -> URLSessionTask{
        let body = MarkWatchlist(mediaType: "movie", mediaId: mediaId, watchlist: isWatch)
        let task = TMDBClient.taskForPostRequest(url: TMDBClient.Endpoints.addToWatchlist.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completionHandler(false, error)
                print(error!)
            }
        }
        return task
    }
    class func downloadPoster(posterPath:String, completionHandler: @escaping (Data?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: TMDBClient.Endpoints.downloadPoster(posterPath).url) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completionHandler(nil, error)

                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }
        task.resume()
        return task
    }
    
    
    
}

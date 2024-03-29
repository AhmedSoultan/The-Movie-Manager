//
//  MovieDetailViewController.swift
//  TheMovieManager

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        if let posterPath = movie.posterPath {
            _ = TMDBClient.downloadPoster(posterPath: posterPath, completionHandler: { (data, error) in
                guard let data = data else {
                    return
                }
                let image = UIImage(data: data)
                self.imageView.image = image
            })
        }
    }
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        _ = TMDBClient.addToWatchlist(mediaId: movie.id, isWatch: !isWatchlist, completionHandler: self.handleAddToWatchlistResponse(success:error:))
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        _ = TMDBClient.markFavoriteMovie(mediaId: movie.id, isFavorite: !isFavorite, completionHandler: self.handleMarkFavorite(success:error:))

    }
    func handleAddToWatchlistResponse(success:Bool, error:Error?) {
        if success {
            if isWatchlist {
                MovieModel.watchlist = MovieModel.watchlist.filter() {$0 != movie}
            } else {
                MovieModel.watchlist.append(movie)
            }
            self.toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        }
    }
    func handleMarkFavorite(success:Bool, error:Error?) {
        if success {
            if isFavorite {
                MovieModel.favorites = MovieModel.favorites.filter() {$0 != movie}
            } else {
                MovieModel.favorites.append(movie)
            }
            toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        }
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    
    
}

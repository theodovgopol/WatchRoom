//
//  SearchVC.swift
//  WatchRoom
//
//  Created by Bogdan on 23/8/20.
//

import UIKit

class SearchVC: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: Variables
    var movieFeed: MovieFeed!
    var movies = [MovieResult]()
    var moviesPage = 1
    var selectedMovie: MovieResult!
    var searchQuery = "avenger"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureCollectionView()
        searchBar.delegate = self
    }
    
    //MARK: CollectionView configuration
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.allowsMultipleSelection = true
        collectionView.contentInset.bottom = 16
        
        collectionView.register(MovieCell.nib, forCellWithReuseIdentifier: MovieCell.id)
        collectionView.register(SectionHeader.nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.id)
    }
    
    func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            switch sectionNumber {
            case 0:
                return self.moviesSection()
            default:
                return self.moviesSection()
            }
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        
        layout.configuration = config
        return layout
    }
    
    //MARK: CollectionViewLayout sections
    
    /// - Tag: Movies section
    func moviesSection() -> NSCollectionLayoutSection {
        
        //define item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        //configurate item
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 16)
        
        //define group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1/3.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        
        
        //define section
        let section = NSCollectionLayoutSection(group: group)
        
        //configure section
        section.contentInsets.leading = 16
        
        //        //configure header
        //        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(45))
        //        section.boundarySupplementaryItems = [
        //            .init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topLeading)
        //        ]
        
        
        return section
    }
    
    func searchMovies(page: Int, section: Int) {
        
        //make sure search query is not empty
        if searchQuery.isEmpty {
            print("query is empty")
            return
        }
        
        let path = TMDB_API.Movies.SearchURL
        let parameters = [
            "api_key": Secrets.MOVIEDB_API_KEY,
            "page": "1",
            "language": UserLocale.language,
            "include_adult": "false",
            "query": searchQuery
        ]
        
        MovieService.shared.getMovies(path: path, parameters: parameters) { [weak self](result) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                case .success(let feed):
                    self.movieFeed = feed
                    if let movies = feed.movies, movies.count > 0 {
                        if page > 1 {
                            var indexPaths = [IndexPath]()
                            for item in 0..<movies.count {
                                let indexPath = IndexPath(row: item + self.movies.count, section: section)
                                indexPaths.append(indexPath)
                            }
                            self.collectionView.performBatchUpdates({
                                self.movies.append(contentsOf: movies)
                                self.collectionView.insertItems(at: indexPaths)
                                
                            }, completion: nil)
                            
                        } else {
                            self.movies.append(contentsOf: movies)
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
}

//MARK: UICollectionViewDelegate implementation
extension SearchVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            selectedMovie = movies[indexPath.row]
        default:break
        }
        
        let storyboard = UIStoryboard(name: StoryboardIDs.MainStoryboard, bundle: nil)
        let movieDetailVC = storyboard.instantiateViewController(withIdentifier: VCIDs.MovieDetailVC) as! MovieDetailVC
        movieDetailVC.id = selectedMovie.id
        present(movieDetailVC, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == movies.count - 2 {
            if moviesPage < movieFeed.totalPages {
                moviesPage += 1
                searchMovies(page: moviesPage, section: 0)
            }
        }
    }
}

//MARK: UICollectionViewDataSource implementation
extension SearchVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return movies.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCell.id, for: indexPath) as! MovieCell
            cell.configure(movie: movies[indexPath.item])
            return cell
        default: return UICollectionViewCell()
        }
    }
}

//MARK: UICollectionViewDelegateFlowLayout implementation
extension SearchVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeader.id, for: indexPath) as! SectionHeader
            
            switch indexPath.section {
            case 0:
                header.configure(section: Section(title: "Trending today"), delegate: nil)
            default: break
            }
            return header
        default: return UICollectionReusableView()
        }
    }
}

//MARK: UISearchBarDelegate implementation
extension SearchVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, query.trimmingCharacters(in: .whitespaces) != "" else {
            print("nothing to search")
            return
        }
        
        searchMovies(query: query)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reload(_:)), object: searchBar)
            perform(#selector(self.reload(_:)), with: searchBar, afterDelay: 0.2)
        }
    }
    
    @objc func reload(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, query.trimmingCharacters(in: .whitespaces) != "" else {
            print("nothing to search")
            return
        }

        searchMovies(query: query)
    }
    
    func searchMovies(query: String) {
        movies.removeAll()
        searchQuery = query
        searchMovies(page: 1, section: 0)
    }
}

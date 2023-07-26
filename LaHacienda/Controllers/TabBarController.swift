//
//  TabBarController.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import UIKit

class TabBarController: UITabBarController, RouterService, TabViewDelegate {
    
    convenience init(router: RouterDelegate){
        self.init()
        self.router = router
    }
    
    deinit {
        print("SE DESTRUYÓ TAB BAR CONTROLLER")
    }
    
    var router: RouterDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tabBar.barTintColor = .systemBackground
        tabBar.tintColor = .systemBlue
        setupVCs()
    }
    
    private func createNavController(for rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        navController.navigationBar.prefersLargeTitles = true
        rootViewController.navigationItem.title = title
        return navController
    }
    
    private func setupVCs() {
        viewControllers = [createNavController(for: HomeViewController(), title: "Inicio", image: UIImage(systemName: "house.circle.fill")!),
                           createNavController(for: OrderViewController(true), title: "Ordenar", image: UIImage(systemName: "drop.circle.fill")!),
                           createNavController(for: HistoryViewController(), title: "Historial", image: UIImage(systemName: "book.circle.fill")!),
                           createNavController(for: SettingViewController(delegate: self), title: "Configuración", image: UIImage(systemName: "person.crop.circle.fill")!)]
    }
    
    func logOut(to newRootViewController: RouterService) {
        viewControllers = nil
        router?.changeRootViewController(to: newRootViewController)
    }
    
}

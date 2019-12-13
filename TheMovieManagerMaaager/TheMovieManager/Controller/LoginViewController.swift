//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    var userName = ""
    var password = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        self.login(true)
        userName = emailTextField.text!
        password = passwordTextField.text!
       _ = TMDBClient.getRequestToken(completionHandler: self.handleRequestToken(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        self.login(true)
        _ = TMDBClient.getRequestToken { (success, error) in
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.open(TMDBClient.Endpoints.validateVieWebSite.url, options: [:], completionHandler: nil)
                }
            } else {
                print(error ?? "")
            }
        }
    }
    func handleRequestToken(success:Bool, error:Error?) {
                if success{
           _ = TMDBClient.login(userName: userName, password: password, completionHandler: self.handleLoginRequest(success:error:))
        } else {
            loginFailure(error?.localizedDescription ?? "")
            print(error!)

        }
        login(false)
    }
    func handleLoginRequest(success:Bool, error:Error?) {
        if success {
            print(TMDBClient.Auth.requestToken)
           _ = TMDBClient.getSessionId(completionHandler: self.handleSessionResponse(success:error:))
        } else {
            loginFailure(error?.localizedDescription ?? "")
            print(error!)
        }
        login(false)
    }
    func handleSessionResponse(success:Bool, error:Error?) {
        if success {
            print(TMDBClient.Auth.sessionId)
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
            }
        } else {
            loginFailure(error?.localizedDescription ?? "")
        }
         self.login(false)
    }
    func login(_ login:Bool) {
        if login{
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !login
        passwordTextField.isEnabled = !login
        loginButton.isEnabled = !login
        loginViaWebsiteButton.isEnabled = !login
    }
    func loginFailure(_ message:String) {
        let errorAlert = UIAlertController(title: "Login failure", message: message, preferredStyle: UIAlertController.Style.alert)
        errorAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
}

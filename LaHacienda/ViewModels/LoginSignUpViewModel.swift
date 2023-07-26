//
//  LoginSignUpViewModel.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class LoginSignUpViewModel {
    
    func newUser(name: String, phone: String, address: String, email: String) {
        let userModel = LaHaciendaUser(name: name, phone: phone, address: address, email: email)
        try? Firestore.firestore().collection(FSCollections.laHaciendaUsers.rawValue).document(userModel.email).setData(from: userModel)
        
    }
}

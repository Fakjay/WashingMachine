import Foundation
import Firebase
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        configureAuthStateChanges()
    }
    
    private func configureAuthStateChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.fetchUserData(uid: user.uid)
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    private func fetchUserData(uid: String) {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                return
            }
            
            if let data = snapshot?.data(),
               let user = try? Firestore.Decoder().decode(User.self, from: data) {
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.error = nil
                }
            }
        }
    }
    
    func signUp(name: String, email: String, password: String, skillLevel: SkillLevel, phoneNumber: String? = nil, location: String? = nil) {
        isLoading = true
        error = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                return
            }
            
            guard let authResult = result else {
                self.isLoading = false
                self.error = "Failed to create account"
                return
            }
            
            let newUser = User(
                id: authResult.user.uid,
                name: name,
                email: email,
                skillLevel: skillLevel,
                phoneNumber: phoneNumber,
                location: location
            )
            
            self.saveUserToFirestore(newUser)
        }
    }
    
    private func saveUserToFirestore(_ user: User) {
        let db = Firestore.firestore()
        
        do {
            try db.collection("users").document(user.id).setData(from: user)
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                return
            }
            
            if let uid = result?.user.uid {
                self.fetchUserData(uid: uid)
            }
        }
    }
    
    func signInWithApple() {
        // Implementation for Apple Sign In would go here
        // Would require additional setup with Apple Developer account
    }
    
    func signInWithGoogle() {
        // Implementation for Google Sign In would go here
        // Would require additional setup with Google Firebase Authentication
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.currentUser = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func updateProfile(name: String? = nil, skillLevel: SkillLevel? = nil, phoneNumber: String? = nil, location: String? = nil) {
        guard var user = currentUser else { return }
        isLoading = true
        
        if let name = name, !name.isEmpty {
            user.name = name
        }
        
        if let skillLevel = skillLevel {
            user.skillLevel = skillLevel
        }
        
        if let phoneNumber = phoneNumber {
            user.phoneNumber = phoneNumber
        }
        
        if let location = location {
            user.location = location
        }
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("users").document(user.id).setData(from: user)
            self.currentUser = user
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
            } else {
                // Successfully sent password reset email
            }
        }
    }
    
    func updateUserStats(win: Bool) {
        guard var user = currentUser else { return }
        
        if win {
            user.wins += 1
        } else {
            user.losses += 1
        }
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("users").document(user.id).updateData([
                "wins": user.wins,
                "losses": user.losses
            ])
            self.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
    }
} 
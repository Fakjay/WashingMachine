import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var isEditingProfile = false
    @State private var showingImagePicker = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    Divider()
                    
                    // Stats Section
                    statsSection
                    
                    // Settings Section
                    settingsSection
                }
                .padding()
                .background(Color(#colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)))
            }
            .navigationTitle("Profile")
            .navigationBarItems(
                trailing: Button(action: {
                    isEditingProfile = true
                }) {
                    Text("Edit")
                }
            )
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingImagePicker) {
                // In a real app, this would handle image selection and upload
                Text("Image picker would go here")
                    .padding()
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            if let user = authService.currentUser {
                // Profile picture
                ZStack {
                    if let avatarURL = user.avatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 120)
                            .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .offset(x: 40, y: 40)
                }
                
                // User name and info
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    Label(user.skillLevel.rawValue, systemImage: "trophy")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(skillLevelColor(for: user.skillLevel).opacity(0.2))
                        .foregroundColor(skillLevelColor(for: user.skillLevel))
                        .cornerRadius(20)
                    
                    Label("\(user.eloRating)", systemImage: "chart.bar")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                }
            } else {
                ProgressView()
                    .padding(.vertical, 60)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Stats")
                .font(.headline)
                .padding(.leading, 5)
            
            if let user = authService.currentUser {
                HStack(spacing: 15) {
                    StatCard(
                        title: "Matches",
                        value: String(user.matchHistory.count),
                        icon: "sportscourt.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Win Rate",
                        value: String(format: "%.0f%%", user.winPercentage * 100),
                        icon: "percent",
                        color: .green
                    )
                }
                
                HStack(spacing: 15) {
                    StatCard(
                        title: "Wins",
                        value: String(user.wins),
                        icon: "trophy.fill",
                        color: .yellow
                    )
                    
                    StatCard(
                        title: "Losses",
                        value: String(user.losses),
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
                .padding(.leading, 5)
            
            Button(action: {
                isEditingProfile = true
            }) {
                SettingsRow(icon: "person.fill", title: "Edit Profile", color: .blue)
            }
            
            NavigationLink(destination: MatchHistoryView()) {
                SettingsRow(icon: "clock.arrow.circlepath", title: "Match History", color: .orange)
            }
            
            Button(action: {
                // In a real app, this would navigate to notifications settings
            }) {
                SettingsRow(icon: "bell.fill", title: "Notifications", color: .purple)
            }
            
            Button(action: {
                showingSignOutConfirmation = true
            }) {
                SettingsRow(icon: "arrow.right.square", title: "Sign Out", color: .red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
    
    private func skillLevelColor(for level: SkillLevel) -> Color {
        switch level {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
        .cornerRadius(10)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
        .cornerRadius(10)
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var skillLevel: SkillLevel = .intermediate
    @State private var phoneNumber = ""
    @State private var location = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    
                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("Location", text: $location)
                }
                
                Section {
                    Button(action: updateProfile) {
                        HStack {
                            Spacer()
                            if isUpdating {
                                ProgressView()
                                    .padding(.trailing, 5)
                            }
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isUpdating)
                    .listRowBackground(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private func loadUserData() {
        if let user = authService.currentUser {
            name = user.name
            skillLevel = user.skillLevel
            phoneNumber = user.phoneNumber ?? ""
            location = user.location ?? ""
        }
    }
    
    private func updateProfile() {
        isUpdating = true
        
        authService.updateProfile(
            name: name,
            skillLevel: skillLevel,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            location: location.isEmpty ? nil : location
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isUpdating = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct MatchHistoryView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    
    var body: some View {
        List {
            if matchService.pastMatches.isEmpty {
                Text("No match history yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(matchService.pastMatches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.location)
                                    .font(.headline)
                                
                                Text(match.formattedDate)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let user = authService.currentUser, 
                               isPlayerWinner(userID: user.id, in: match) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Match History")
        .onAppear {
            if let userID = authService.currentUser?.id {
                matchService.fetchMatches(for: userID)
            }
        }
    }
    
    private func isPlayerWinner(userID: String, in match: Match) -> Bool {
        // In a real app, this would check if the user was on a winning team
        // For now, this is just a placeholder implementation
        return false
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthService())
    }
} 
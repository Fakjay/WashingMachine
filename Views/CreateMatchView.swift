import SwiftUI

struct CreateMatchView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    @Binding var isPresented: Bool
    
    @State private var location = ""
    @State private var date = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var courtNumbers = ["1"]
    @State private var maxPlayers = 8
    @State private var visibility: MatchVisibility = .public
    @State private var inviteCode = ""
    @State private var generateRandomInviteCode = true
    @State private var gamesPerSet = 6
    @State private var enableGoldenPoint = true
    @State private var numberOfRounds = 3
    
    @State private var showingCourtsSheet = false
    @State private var courtNumberInput = ""
    
    @State private var isSubmitting = false
    
    private let maxPlayersOptions = [4, 8, 12, 16, 20]
    private let gamesPerSetOptions = [4, 6, 8]
    private let roundsOptions = [1, 2, 3, 4, 5]
    
    var body: some View {
        NavigationView {
            Form {
                // Basic match details
                Section(header: Text("Match Details")) {
                    TextField("Location", text: $location)
                        .autocapitalization(.words)
                    
                    DatePicker("Date & Time", selection: $date, in: Date()...)
                    
                    Picker("Maximum Players", selection: $maxPlayers) {
                        ForEach(maxPlayersOptions, id: \.self) { option in
                            Text("\(option)").tag(option)
                        }
                    }
                    
                    // Court numbers
                    HStack {
                        Text("Court Numbers")
                        Spacer()
                        Button(action: {
                            showingCourtsSheet = true
                        }) {
                            Text(courtNumbers.joined(separator: ", "))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Match visibility
                Section(header: Text("Access")) {
                    Picker("Visibility", selection: $visibility) {
                        ForEach(MatchVisibility.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if visibility == .private {
                        Toggle("Generate random code", isOn: $generateRandomInviteCode)
                        
                        if !generateRandomInviteCode {
                            TextField("Invite Code", text: $inviteCode)
                                .autocapitalization(.none)
                        }
                    }
                }
                
                // Match rules
                Section(header: Text("Match Rules")) {
                    Picker("Games per Set", selection: $gamesPerSet) {
                        ForEach(gamesPerSetOptions, id: \.self) { option in
                            Text("\(option)").tag(option)
                        }
                    }
                    
                    Toggle("Enable Golden Point", isOn: $enableGoldenPoint)
                    
                    Picker("Number of Rounds", selection: $numberOfRounds) {
                        ForEach(roundsOptions, id: \.self) { option in
                            Text("\(option)").tag(option)
                        }
                    }
                }
                
                // Create button
                Section {
                    Button(action: createMatch) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 5)
                            }
                            Text("Create Match")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting || !isFormValid)
                    .listRowBackground(isFormValid ? Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)) : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Create Match")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
            .sheet(isPresented: $showingCourtsSheet) {
                CourtNumbersSheet(
                    courtNumbers: $courtNumbers,
                    courtNumberInput: $courtNumberInput
                )
            }
            .alert(item: Binding<AlertItem?>(
                get: {
                    if let error = matchService.error {
                        return AlertItem(message: error)
                    }
                    return nil
                },
                set: { _ in matchService.error = nil }
            )) { alertItem in
                Alert(title: Text("Error"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var isFormValid: Bool {
        !location.isEmpty &&
        date > Date() &&
        !courtNumbers.isEmpty &&
        (visibility == .public || generateRandomInviteCode || !inviteCode.isEmpty)
    }
    
    private func createMatch() {
        guard let currentUser = authService.currentUser else { return }
        
        isSubmitting = true
        
        let finalInviteCode: String? = {
            if visibility == .private {
                if generateRandomInviteCode {
                    return generateInviteCode()
                } else {
                    return inviteCode
                }
            }
            return nil
        }()
        
        matchService.createMatch(
            creatorID: currentUser.id,
            date: date,
            location: location,
            courtNumbers: courtNumbers,
            maxPlayers: maxPlayers,
            visibility: visibility,
            inviteCode: finalInviteCode,
            gamesPerSet: gamesPerSet,
            enableGoldenPoint: enableGoldenPoint,
            numberOfRounds: numberOfRounds
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            if matchService.error == nil {
                isPresented = false
            }
        }
    }
    
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let length = 6
        
        return String((0..<length).map { _ in
            characters.randomElement()!
        })
    }
}

struct CourtNumbersSheet: View {
    @Binding var courtNumbers: [String]
    @Binding var courtNumberInput: String
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Assign Court Numbers")
                    .font(.headline)
                    .padding(.top, 20)
                
                Text("Please add at least one court number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Court number", text: $courtNumberInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        addCourtNumber()
                    }) {
                        Text("Add")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(courtNumberInput.isEmpty)
                }
                .padding(.horizontal)
                
                List {
                    ForEach(courtNumbers, id: \.self) { number in
                        Text("Court \(number)")
                    }
                    .onDelete(perform: deleteCourtNumbers)
                }
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addCourtNumber() {
        guard !courtNumberInput.isEmpty else { return }
        
        if !courtNumbers.contains(courtNumberInput) {
            courtNumbers.append(courtNumberInput)
        }
        
        courtNumberInput = ""
    }
    
    private func deleteCourtNumbers(at offsets: IndexSet) {
        courtNumbers.remove(atOffsets: offsets)
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct CreateMatchView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMatchView(isPresented: .constant(true))
            .environmentObject(AuthService())
            .environmentObject(MatchService())
    }
} 
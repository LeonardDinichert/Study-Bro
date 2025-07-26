//
//  CollectInformationView.swift
//  StuddyBuddy
//
//  Created by Léonard Dinichert on 11.04.2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct UserInfosCreation: View {
    
    @AppStorage("showSignInView") private var showSignInView: Bool = true
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var selectedItem: PhotosPickerItem? = nil
    
    @State private var displayNotFilledAlert = false
    
    @StateObject private var viewModel = userManagerViewModel()
    @State private var profileImageData: Data? = nil
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName
        case lastName
        case username
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Please complete the information below to finish your registration")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // First Name
                    CustomTextField(text: $firstName, placeholder: "Surname")
                        .focused($focusedField, equals: .firstName)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Last Name
                    CustomTextField(text: $lastName, placeholder: "Name")
                        .focused($focusedField, equals: .lastName)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Username
                    CustomTextField(text: $username, placeholder: "Username")
                        .focused($focusedField, equals: .username)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Birth Date
                    DatePicker("Birthdate", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .cardStyle()
                        .padding(.horizontal)
                    
                    
                    // Profile Image Picker
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                            
                            Text("Add a profile picture")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                        .cardStyle()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }
                    .onChange(of: selectedItem) { oldItem, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                self.profileImageData = data
                            } else {
                                print("Failed to load image data")
                            }
                        }
                    }
                    
                    // Display the selected image if available
                    if let imageData = profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()
                    }
                    
                    
                    // Finish Registration Button
                    Button(action: {
                        Task {
                            await finishRegistration()
                        }
                    }) {
                        Text("Finish Registration")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(firstName.isEmpty || lastName.isEmpty || username.isEmpty || profileImageData == nil)
                    
                    // Spacer
                    Spacer()
                }
                .padding()
            }
            .padding(.top)
            .onTapGesture {
                focusedField = nil
            }
            .alert(isPresented: $displayNotFilledAlert) {
                Alert(
                    title: Text("Informations manquantes"),
                    message: Text("Veuillez remplir toutes les informations demandées."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                try await viewModel.loadCurrentUser()
            }
        }
    }
    
    // Function to finish registration
    func finishRegistration() async {
        
        if firstName.isEmpty || lastName.isEmpty || username.isEmpty || profileImageData == nil {
            self.displayNotFilledAlert = true
            return
        }
        
        Task {

            let userId = try AuthService.shared.getAuthenticatedUser().uid
            
            
            if let profileImageData = profileImageData {
                print(profileImageData)
                do {
                    try await viewModel.saveProfileImage(data: profileImageData, userId: userId)
                } catch {
                    print(error)
                }
            }
            
            let currentDate = Date()
            let age = calculateAge(birthDate: self.birthDate, currentDate: currentDate)
            
            // Ensure age is not negative or invalid
            if age <= 0 {
                print("age is invalid")
                self.displayNotFilledAlert = true
                return
            }
            
            try await UserManager.shared.updateUserInfo(
                userId: userId,
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                username: username,
            )
            
            
            print("Informations registred successfully")
            
            showSignInView = false
        }
        
    }
    
    func calculateAge(birthDate: Date, currentDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        let age = ageComponents.year ?? 0
        return max(age, 0)
    }
}

#Preview {
    UserInfosCreation()
}

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
                VStack(spacing: 20) {
                    
                    Text("Please complete the information below to continue your registration")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                    
                    // First Name
                    CustomTextField(text: $firstName, placeholder: "Surname")
                        .focused($focusedField, equals: .firstName)
                        .cardStyle()
                        .padding(.horizontal)
                        .frame(maxHeight: 50)
                    
                    
                    // Last Name
                    CustomTextField(text: $lastName, placeholder: "Name")
                        .focused($focusedField, equals: .lastName)
                        .cardStyle()
                        .padding(.horizontal)
                        .frame(maxHeight: 50)

                    
                    // Username
                    CustomTextField(text: $username, placeholder: "Username")
                        .focused($focusedField, equals: .username)
                        .cardStyle()
                        .padding(.horizontal)
                        .frame(maxHeight: 50)

                    
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
                            
                            Spacer()
                        }
                       
                    }
                    .cardStyle()
                    .padding(.horizontal)
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
                            .glassEffect()
                            .clipShape(Circle())

                    }
                    
                    Spacer()
                    
                    // Finish Registration Button
                    NavigationLink{
                        moreInfoAboutUser(
                            firstName: $firstName,
                            lastName: $lastName,
                            username: $username,
                            birthDate: $birthDate,
                            selectedItem: $selectedItem,
                            profileImageData: $profileImageData,
                            displayNotFilledAlert: $displayNotFilledAlert,
                            showSignInView: $showSignInView
                        )
                        .glassEffect()
                        .clipShape(.rect(cornerRadius: 28))
                        .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 14, x: 0, y: 8)
                        .tint(AppTheme.primaryColor)
                        .padding(.horizontal)
                    } label: {
                        Text("Continue")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryColor)
                            .foregroundColor(.white)
                            .clipShape(.rect(cornerRadius: 28))
                            .shadow(color: AppTheme.primaryColor.opacity(0.7), radius: 10, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .disabled(firstName.isEmpty || lastName.isEmpty || username.isEmpty || profileImageData == nil)
                    
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
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                try await viewModel.loadCurrentUser()
            }
        }
    }
    
    
}

#Preview {
    UserInfosCreation()
}

struct moreInfoAboutUser: View {
    
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var username: String
    @Binding var birthDate: Date
    @Binding var selectedItem: PhotosPickerItem?
    
    @Binding var profileImageData: Data?
    @Binding var displayNotFilledAlert: Bool
    @Binding var showSignInView: Bool
    
    @State private var discoverySource: String = ""
    @State private var usagePurpose: String = ""
    
    var discoveryOptions = ["School", "Instagram", "TikTok", "Friends", "Family"]
    var usageOptions = ["Middle School", "High School", "University", "Day to Day Life"]
    
    var body: some View {
        VStack(spacing: 25) {
            
            VStack(alignment: .center, spacing: 10) {
                Text("How did you discover StuddyBuddy?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Picker("How did you discover the app?", selection: $discoverySource) {
                    ForEach(discoveryOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.automatic)
                .tint(AppTheme.primaryColor)
                .glassEffect()
                .padding(5)
                .padding(.top)
            }
            .padding()
            //.shadow(color: AppTheme.primaryColor.opacity(0.6), radius: 12, x: 0, y: 8)
            .padding(.horizontal)
            
            VStack(alignment: .center, spacing: 10) {
                Text("What are you using StuddyBuddy for?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Picker("What are you using StuddyBuddy for?", selection: $usagePurpose) {
                    ForEach(usageOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .tint(AppTheme.primaryColor)
                .pickerStyle(.automatic)
                .glassEffect()
                .padding(5)
                .padding(.top)

            }
            .padding()
            //.shadow(color: Color.purple.opacity(0.6), radius: 12, x: 0, y: 8)
            .padding(.horizontal)
            
            Spacer()
            
            VStack {
                Text("Thank you for using StuddyBuddy !")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryColor)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            
            
            Button("Finish registration") {
                Task {
                    await finishRegistration()
                }
            }
            .font(.title3)
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
            .background(discoverySource.isEmpty || usagePurpose.isEmpty ? Color.gray.opacity(0.4) : AppTheme.primaryColor)
            .foregroundColor(.white)
            .clipShape(.rect(cornerRadius: 28))
            .shadow(color: discoverySource.isEmpty || usagePurpose.isEmpty ? Color.clear : AppTheme.primaryColor.opacity(0.7), radius: 10, x: 0, y: 6)
            .disabled(discoverySource.isEmpty || usagePurpose.isEmpty)
            .padding(.horizontal)
            .padding(.vertical)
            
        }
    }
    
    // Function to finish registration
    func finishRegistration() async {
        if firstName.isEmpty || lastName.isEmpty || username.isEmpty || profileImageData == nil || discoverySource.isEmpty || usagePurpose.isEmpty {
            self.displayNotFilledAlert = true
            return
        }

        do {
            let userId = try AuthService.shared.getAuthenticatedUser().uid
            var profileImageURL: String? = nil

            // Attempt to upload profile image and retrieve URL
            if let profileImageData = profileImageData {
                do {
                    let (path, _) = try await StorageManager.shared.saveImage(data: profileImageData, userId: userId)
                    let url = try await StorageManager.shared.getUrlForImage(path: path)
                    profileImageURL = url.absoluteString
                } catch {
                    print("Failed to upload profile image: \(error)")
                    self.displayNotFilledAlert = true
                    return
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

            // Batch user information (with age, profileImageURL, discoverySource, usagePurpose)
            var data: [String: Any] = [
                "first_name": firstName,
                "last_name": lastName,
                "username": username,
                "birthdate": birthDate,
                "age": age,
                "user_id": userId,
                "discovery_source": discoverySource,
                "usage_purpose": usagePurpose
            ]
            if let profileImageURL = profileImageURL {
                data["profile_image_path_url"] = profileImageURL
            }

            do {
                try await UserManager.shared.userDocument(userId: userId).setData(data, merge: true)
            } catch {
                print("Failed to save user info: \(error)")
                self.displayNotFilledAlert = true
                return
            }

            print("Informations registered successfully")
            showSignInView = false
        } catch {
            print("Unexpected error: \(error)")
            self.displayNotFilledAlert = true
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
    moreInfoAboutUser(
        firstName: .constant("PreviewFirst"),
        lastName: .constant("PreviewLast"),
        username: .constant("PreviewUsername"),
        birthDate: .constant(Date()),
        selectedItem: .constant(nil),
        profileImageData: .constant(Data()),
        displayNotFilledAlert: .constant(false),
        showSignInView: .constant(true)
    )
}

//
//  ContentView.swift
//  Laurier Connect
//
//  Created by Chukwuka Okwusiuno on 2024-10-17.
//

import SwiftUI

// MARK: - Models
struct User: Identifiable, Codable, Hashable {
    let id: String
    var fullName: String
    var email: String
    var major: String
    var profileImage: Data?
    var connections: Set<String>
    
    // Add initializer with default empty connections
    init(id: String, fullName: String, email: String, major: String, profileImage: Data? = nil, connections: Set<String> = []) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.major = major
        self.profileImage = profileImage
        self.connections = connections
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

struct Post: Identifiable {
    let id = UUID()
    let author: User
    let content: String
    let timestamp: Date
    var comments: [Comment]
}

struct Comment: Identifiable {
    let id = UUID()
    let author: User
    let content: String
    let timestamp: Date
}

struct Message: Identifiable, Codable, Equatable {
    let id = UUID()
    let senderId: String
    let content: String
    let timestamp: Date
    let isGroupMessage: Bool
    let groupId: String?
    
    // Implement Equatable
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

struct Chat: Identifiable, Equatable {
    let id = UUID()
    let participants: [User]
    var messages: [Message]
    let isGroup: Bool
    let groupName: String?
    
    // Implement Equatable
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
}

struct Event: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let location: String
    let startTime: Date
    let endTime: Date
    let creatorId: String
    var attendees: [User]
}

// MARK: - Event Store
class EventStore: ObservableObject {
    @Published var events: [Event] = []
    
    func addEvent(_ event: Event) {
        events.append(event)
    }
}

// MARK: - View Models
class UserSettings: ObservableObject {
    @Published var currentUser: User?
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
    }
    
    func updateProfileImage(_ imageData: Data) {
        if var user = currentUser {
            user.profileImage = imageData
            currentUser = user
        }
    }
}

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    func addPost(content: String, author: User) {
        let post = Post(author: author, content: content, timestamp: Date(), comments: [])
        posts.insert(post, at: 0)
    }
    
    func addComment(to post: Post, content: String, author: User) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            let comment = Comment(author: author, content: content, timestamp: Date())
            posts[index].comments.append(comment)
        }
    }
}

// Add MessageStore to manage all chats and messages
class MessageStore: ObservableObject {
    @Published var chats: [Chat] = []
    
    func createOrUpdateChat(with user: User, currentUser: User, message: Message? = nil) {
        if let existingChatIndex = chats.firstIndex(where: { chat in
            chat.participants.contains(where: { $0.id == user.id })
        }) {
            // Update existing chat
            if let message = message {
                chats[existingChatIndex].messages.append(message)
            }
        } else {
            // Create new chat
            let newChat = Chat(
                participants: [currentUser, user],
                messages: message.map { [$0] } ?? [],
                isGroup: false,
                groupName: nil
            )
            chats.append(newChat)
        }
    }
}

// MARK: - App Entry Point
@main
struct LaurierConnectApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var messageStore = MessageStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(feedViewModel)
                .environmentObject(messageStore)
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Group {
            if !userSettings.isLoggedIn {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
    }
}

struct WelcomeView: View {
    @State private var email = ""
    @State private var showingLogin = false
    @State private var showingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 30) {
                    // Logo
                    Image(systemName: "bird.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 160, height: 160)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                    
                    Text("Laurier Connect")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Email Input
                    TextField("Enter your @mylaurier.ca email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 32)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { validateAndShowLogin() }) {
                            Text("Login")
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { validateAndShowSignUp() }) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
            .sheet(isPresented: $showingLogin) {
                LoginView(email: email)
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(email: email)
            }
            .alert("Invalid Email", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateEmail() -> Bool {
        if email.isEmpty {
            alertMessage = "Please enter your email address"
            return false
        }
        if !email.hasSuffix("@mylaurier.ca") {
            alertMessage = "Please use your @mylaurier.ca email address"
            return false
        }
        return true
    }
    
    private func validateAndShowLogin() {
        if validateEmail() {
            showingLogin = true
        } else {
            showingAlert = true
        }
    }
    
    private func validateAndShowSignUp() {
        if validateEmail() {
            showingSignUp = true
        } else {
            showingAlert = true
        }
    }
}

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    let email: String
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: .constant(email))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Login") {
                    login()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
            .padding()
            .navigationTitle("Login")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func login() {
        let user = User(
            id: UUID().uuidString,
            fullName: "Test User",
            email: email,
            major: "Undeclared"
        )
        userSettings.login(user: user)
        dismiss()
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    let email: String
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var major = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: .constant(email))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Major", text: $major)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Sign Up") {
                    signUp()
                }
                .buttonStyle(.borderedProminent)
                .disabled(fullName.isEmpty || password.isEmpty || confirmPassword.isEmpty || major.isEmpty)
            }
            .padding()
            .navigationTitle("Sign Up")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func signUp() {
        let user = User(
            id: UUID().uuidString,
            fullName: fullName,
            email: email,
            major: major
        )
        userSettings.login(user: user)
        dismiss()
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
            
            ConnectView()
                .tabItem {
                    Label("Connect", systemImage: "person.2.fill")
                }
            
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct FeedView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var userSettings: UserSettings
    @State private var newPostContent = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // New post input
                HStack {
                    TextField("What's on your mind?", text: $newPostContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Post") {
                        if let user = userSettings.currentUser {
                            feedViewModel.addPost(content: newPostContent, author: user)
                            newPostContent = ""
                        }
                    }
                    .disabled(newPostContent.isEmpty)
                }
                .padding()
                
                // Posts list
                List(feedViewModel.posts) { post in
                    PostCard(post: post)
                }
            }
            .navigationTitle("Feed")
        }
    }
}

struct PostCard: View {
    let post: Post
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var userSettings: UserSettings
    @State private var newComment = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author info
            Text(post.author.fullName)
                .font(.headline)
            
            // Content
            Text(post.content)
                .padding(.vertical, 4)
            
            // Comments
            ForEach(post.comments) { comment in
                HStack {
                    Text(comment.author.fullName)
                        .fontWeight(.medium)
                    Text(comment.content)
                }
                .font(.subheadline)
                .padding(.leading)
            }
            
            // Add comment
            HStack {
                TextField("Add comment", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    if let user = userSettings.currentUser {
                        feedViewModel.addComment(to: post, content: newComment, author: user)
                        newComment = ""
                    }
                }
                .disabled(newComment.isEmpty)
            }
        }
        .padding()
    }
}

struct ProfileView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Picture
                Button(action: { showingImagePicker = true }) {
                    if let imageData = userSettings.currentUser?.profileImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.purple)
                            )
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $profileImage)
                }
                .onChange(of: profileImage) { newImage in
                    if let image = newImage,
                       let imageData = image.jpegData(compressionQuality: 0.8) {
                        userSettings.updateProfileImage(imageData)
                    }
                }
                
                Text(userSettings.currentUser?.fullName ?? "")
                    .font(.title2)
                
                Text(userSettings.currentUser?.email ?? "")
                    .foregroundColor(.gray)
                
                Button("Logout") {
                    userSettings.logout()
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

struct ConnectView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "Name"
    let filters = ["Name", "Laurier ID", "Major"]
    
    // Mock student data - replace with real data later
    let students = [
        User(id: "200578934", fullName: "John Smith", email: "smit2090@mylaurier.ca", major: "Computer Science"),
        User(id: "200512345", fullName: "Emma Wilson", email: "wils1234@mylaurier.ca", major: "Business"),
        User(id: "200598765", fullName: "Michael Brown", email: "brow5678@mylaurier.ca", major: "Psychology")
    ]
    
    var filteredStudents: [User] {
        if searchText.isEmpty {
            return students
        }
        
        switch selectedFilter {
        case "Name":
            return students.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
        case "Laurier ID":
            return students.filter { $0.id.contains(searchText) }
        case "Major":
            return students.filter { $0.major.lowercased().contains(searchText.lowercased()) }
        default:
            return students
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Section
                VStack(spacing: 10) {
                    // Filter Picker
                    Picker("Search by", selection: $selectedFilter) {
                        ForEach(filters, id: \.self) { filter in
                            Text(filter).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search \(selectedFilter.lowercased())...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Results List
                if filteredStudents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No students found")
                            .font(.headline)
                        Text("Try adjusting your search")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredStudents) { student in
                        StudentCard(student: student)
                    }
                }
            }
            .navigationTitle("Connect")
        }
    }
}

struct StudentCard: View {
    let student: User
    @State private var isConnected = false
    @State private var showingChat = false
    @State private var showingAlert = false
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var messageStore: MessageStore
    @StateObject private var connectionManager = ConnectionManager()
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile Picture
            if let imageData = student.profileImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(student.fullName.prefix(1))
                            .font(.title2)
                            .foregroundColor(.purple)
                    )
            }
            
            // Student Info
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.headline)
                Text("ID: \(student.id)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(student.major)
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 10) {
                // Message Button
                Button(action: {
                    if connectionManager.isConnected(with: student.id) {
                        showingChat = true
                    } else {
                        showingAlert = true
                    }
                }) {
                    Image(systemName: "message.fill")
                        .foregroundColor(connectionManager.isConnected(with: student.id) ? .purple : .gray)
                        .padding(8)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Connect Button
                Button(action: toggleConnection) {
                    Text(connectionManager.isConnected(with: student.id) ? "Connected" : "Connect")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(connectionManager.isConnected(with: student.id) ? Color.green : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingChat) {
            if let currentUser = userSettings.currentUser {
                NavigationView {
                    ChatView(
                        viewModel: ChatViewModel(
                            messageStore: messageStore,
                            otherUser: student
                        ),
                        otherUser: student
                    )
                }
            }
        }
        .alert("Connection Required", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need to connect with this user before sending messages.")
        }
    }
    
    private func toggleConnection() {
        if connectionManager.isConnected(with: student.id) {
            connectionManager.disconnect(from: student.id)
        } else {
            connectionManager.connect(with: student.id)
        }
        isConnected = connectionManager.isConnected(with: student.id)
    }
}

// MARK: - Connection Manager
class ConnectionManager: ObservableObject {
    @Published var connections: Set<String> = []
    
    func connect(with userId: String) {
        connections.insert(userId)
    }
    
    func disconnect(from userId: String) {
        connections.remove(userId)
    }
    
    func isConnected(with userId: String) -> Bool {
        connections.contains(userId)
    }
}

// Add ImagePicker for profile photos
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Update ChatViewModel
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private let messageStore: MessageStore
    let otherUser: User
    
    init(messageStore: MessageStore, otherUser: User) {
        self.messageStore = messageStore
        self.otherUser = otherUser
        
        // Load existing messages if any
        if let existingChat = messageStore.chats.first(where: { chat in
            chat.participants.contains(where: { $0.id == otherUser.id })
        }) {
            self.messages = existingChat.messages
        }
    }
    
    func sendMessage(content: String, from sender: User) {
        let newMessage = Message(
            senderId: sender.id,
            content: content,
            timestamp: Date(),
            isGroupMessage: false,
            groupId: nil
        )
        messages.append(newMessage)
        messageStore.createOrUpdateChat(with: otherUser, currentUser: sender, message: newMessage)
    }
}

// Update MessagesView
struct MessagesView: View {
    @State private var showingNewMessage = false
    @State private var showingNewGroup = false
    @EnvironmentObject var messageStore: MessageStore
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        NavigationView {
            List {
                // Private Chats Section
                Section(header: Text("Direct Messages")) {
                    ForEach(messageStore.chats.filter { !$0.isGroup }) { chat in
                        let otherUser = chat.participants.first { $0.id != userSettings.currentUser?.id } ?? chat.participants[1]
                        NavigationLink {
                            ChatView(
                                viewModel: ChatViewModel(
                                    messageStore: messageStore,
                                    otherUser: otherUser
                                ),
                                otherUser: otherUser
                            )
                        } label: {
                            ChatRow(chat: chat)
                        }
                    }
                }
                
                // Group Chats Section
                Section(header: Text("Group Chats")) {
                    ForEach(messageStore.chats.filter { $0.isGroup }) { chat in
                        let otherUser = chat.participants.first { $0.id != userSettings.currentUser?.id } ?? chat.participants[1]
                        NavigationLink {
                            ChatView(
                                viewModel: ChatViewModel(
                                    messageStore: messageStore,
                                    otherUser: otherUser
                                ),
                                otherUser: otherUser
                            )
                        } label: {
                            ChatRow(chat: chat)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewMessage = true }) {
                            Label("New Message", systemImage: "square.and.pencil")
                        }
                        Button(action: { showingNewGroup = true }) {
                            Label("New Group", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView()
            }
            .sheet(isPresented: $showingNewGroup) {
                NewGroupView()
            }
        }
    }
}

// MARK: - Chat Row
struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            // Chat Avatar
            Group {
                if chat.isGroup {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.purple)
                        )
                } else {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(chat.participants[1].fullName.prefix(1))
                                .font(.title2)
                                .foregroundColor(.purple)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.isGroup ? (chat.groupName ?? "Group Chat") : chat.participants[1].fullName)
                    .font(.headline)
                if let lastMessage = chat.messages.last {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let lastMessage = chat.messages.last {
                Text(formatDate(lastMessage.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Chat View
struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    let otherUser: User
    @State private var messageText = ""
    @EnvironmentObject var userSettings: UserSettings
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages ScrollView
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                currentUserId: userSettings.currentUser?.id ?? ""
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input Bar
            VStack {
                Divider()
                HStack(spacing: 12) {
                    // Text Input Field
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...5)
                        .padding(.vertical, 8)
                    
                    // Send Button
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(messageText.isEmpty ? .gray : .purple)
                            .font(.system(size: 20))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(messageText.isEmpty ? Color.gray.opacity(0.1) : Color.purple.opacity(0.2))
                            )
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
    
    private func sendMessage() {
        guard let currentUser = userSettings.currentUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage(
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            from: currentUser
        )
        messageText = ""
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let currentUserId: String
    
    var isCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.purple : Color(.systemGray6))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(20)
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal, 8)
        .id(message.id) // For ScrollViewReader
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - New Message View
struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var messageStore: MessageStore
    @State private var searchText = ""
    @State private var selectedFilter = "Name"
    @State private var showingChat = false
    @State private var selectedUser: User?
    let filters = ["Name", "Laurier ID", "Email"]
    
    // Replace with real user data later
    let users = [
        User(id: "200578934", fullName: "John Smith", email: "smit2090@mylaurier.ca", major: "Computer Science"),
        User(id: "200512345", fullName: "Emma Wilson", email: "wils1234@mylaurier.ca", major: "Business"),
        User(id: "200598765", fullName: "Michael Brown", email: "brow5678@mylaurier.ca", major: "Psychology")
    ]
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        }
        
        switch selectedFilter {
        case "Name":
            return users.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
        case "Laurier ID":
            return users.filter { $0.id.contains(searchText) }
        case "Email":
            return users.filter { $0.email.lowercased().contains(searchText.lowercased()) }
        default:
            return users
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Section
                VStack(spacing: 10) {
                    // Filter Picker
                    Picker("Search by", selection: $selectedFilter) {
                        ForEach(filters, id: \.self) { filter in
                            Text(filter).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search \(selectedFilter.lowercased())...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Results List
                if filteredUsers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No users found")
                            .font(.headline)
                        Text("Try adjusting your search")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredUsers) { user in
                        Button(action: { startChat(with: user) }) {
                            UserRow(user: user)
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func startChat(with user: User) {
        if let currentUser = userSettings.currentUser {
            dismiss()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController as? UITabBarController,
               let navigationController = tabBarController.selectedViewController as? UINavigationController {
                let chatView = ChatView(
                    viewModel: ChatViewModel(
                        messageStore: messageStore,
                        otherUser: user
                    ),
                    otherUser: user
                )
                let hostingController = UIHostingController(rootView: chatView)
                navigationController.pushViewController(hostingController, animated: true)
            }
        }
    }
}

// MARK: - User Row
struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.fullName.prefix(1))
                        .font(.title2)
                        .foregroundColor(.purple)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                Text("ID: \(user.id)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - New Group View
struct NewGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedUsers = Set<User>()
    @State private var groupName = ""
    @State private var showingNamePrompt = false
    
    // Replace with real user data
    let users = [User]()
    
    var body: some View {
        NavigationView {
            VStack {
                // Selected users
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(selectedUsers)) { user in
                                SelectedUserBubble(user: user) {
                                    selectedUsers.remove(user)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // User list
                List(users) { user in
                    Button(action: { toggleUser(user) }) {
                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.fullName.prefix(1))
                                        .foregroundColor(.purple)
                                )
                            
                            Text(user.fullName)
                            
                            Spacer()
                            
                            if selectedUsers.contains(user) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
            }
            .navigationTitle("New Group")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") {
                    showingNamePrompt = true
                }
                .disabled(selectedUsers.count < 2)
            )
            .alert("Group Name", isPresented: $showingNamePrompt) {
                TextField("Enter group name", text: $groupName)
                Button("Cancel", role: .cancel) { }
                Button("Create") { createGroup() }
            }
        }
    }
    
    private func toggleUser(_ user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }
    
    private func createGroup() {
        // Implement group creation
        dismiss()
    }
}

struct SelectedUserBubble: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(user.fullName)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .cornerRadius(15)
    }
}

// MARK: - Events View
struct EventsView: View {
    @StateObject private var eventStore = EventStore()
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(eventStore.events) { event in
                    EventRow(event: event)
                }
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(eventStore: eventStore)
            }
        }
    }
}

// MARK: - Add Event View
struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var eventStore: EventStore
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // Default 1 hour duration
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Starts", selection: $startTime)
                    DatePicker("Ends", selection: $endTime)
                }
            }
            .navigationTitle("New Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { createEvent() }
                    .disabled(title.isEmpty || location.isEmpty || endTime <= startTime)
            )
        }
    }
    
    private func createEvent() {
        if let currentUser = userSettings.currentUser {
            let newEvent = Event(
                title: title,
                description: description,
                location: location,
                startTime: startTime,
                endTime: endTime,
                creatorId: currentUser.id,
                attendees: [currentUser]
            )
            eventStore.addEvent(newEvent)
            dismiss()
        }
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.headline)
            
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.purple)
                Text(event.location)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.purple)
                Text(formatEventTime(start: event.startTime, end: event.endTime))
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatEventTime(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}





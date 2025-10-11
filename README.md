# 🤖 ScaleX AI Chatbot

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A cross-platform AI-powered mobile chatbot application built with Flutter, featuring multiple AI models, bilingual support (English/Arabic), and advanced chat management capabilities.

---

## 📱 Download & Test

### 🔗 **[Download APK from Google Drive](https://drive.google.com/file/d/11ZBYpsEccF89jgQVAwf1sPPaFReYQj50/view?usp=sharing)**


### System Requirements
- **Android**: 5.0 (API Level 21) or higher
- **iOS**: iOS 12.0 or higher (if built)
- **Storage**: ~50 MB
- **Internet**: Required for AI features

---

## ✨ Key Features

### 🎯 Core Functionality

#### 1. **Multi-AI Model Support**
- Switch seamlessly between three powerful AI models:
    - **Groq (Llama 3.1)** - Lightning-fast responses with efficient processing
    - **Claude AI** - Thoughtful and detailed conversational AI
    - **OpenAI GPT** - Industry-leading language model
- Real-time model switching without losing conversation context
- Model-specific response indicators

#### 2. **Bilingual Interface (English/Arabic)**
- Complete internationalization (i18n) support
- Automatic RTL (Right-to-Left) layout for Arabic
- Language toggle available on landing screen and settings
- All UI elements, error messages, and prompts fully translated
- AI responses in user's selected language

#### 3. **Secure Authentication**
- Firebase-powered email/password authentication
- Secure user registration and login
- Password validation (minimum 6 characters)
- "Forgot Password" functionality
- Session persistence across app restarts
- Localized error messages

#### 4. **Modern Chat Interface**
- WhatsApp-style message bubbles
- Real-time message streaming
- User messages aligned right (Blue bubbles)
- AI responses aligned left (Gray bubbles)
- Timestamp for each message
- Copy-to-clipboard functionality for AI responses
- Smooth scrolling animations
- Loading indicators during AI processing

#### 5. **AI-Generated User Summary**
- On-demand analysis of your chat patterns
- Click "Generate Summary" button to analyze your conversations
- Uses your selected AI model for personalized insights
- Identifies common topics and interests
- Shows summary based on last 20 messages
- Refresh capability to regenerate with latest data
- Available in both English and Arabic

#### 6. **Offline Chat History**
- Local storage using Hive database
- Access your conversations anytime, even offline
- Fast message retrieval
- Persistent across app sessions
- Automatic data synchronization

#### 7. **User Profile & Settings**
- View account information (email, member since date)
- Track message statistics
- **Language Selection**: Switch between English and Arabic
- **Theme Selection**: Light, Dark, or System default
- **Export Chat History**: PDF or Text format (coming soon)
- **Clear History**: Remove all conversations with confirmation
- Secure logout functionality

---

## 🎨 User Interface Highlights

### Landing Screen
- Eye-catching hero section with app branding
- Clear call-to-action buttons (Login/Sign Up)
- Language toggle (English ↔ العربية)
- Smooth animations and transitions

### Authentication Screens
- Clean, modern design
- Email and password input fields
- Show/hide password toggle
- Real-time validation feedback
- Localized error messages
- Loading states during processing

### Chat Screen
- Minimalist, distraction-free interface
- AI model selector in app bar
- Message input field with send button
- Auto-scroll to latest message
- Empty state with helpful prompt
- Loading indicator for AI responses

### Profile Screen
- User avatar with initial
- Account statistics
- Organized settings sections
- Visual feedback for all actions
- Confirmation dialogs for destructive actions

---

## 🚀 Technical Highlights

### Architecture
- **Clean Architecture** with feature-based organization
- **MVVM Pattern** for separation of concerns
- **Repository Pattern** for data management
- Modular and scalable codebase

### State Management
- **Riverpod** for efficient state management
- Provider-based dependency injection
- Reactive state updates
- Memory-efficient implementation

### Networking
- **Dio** HTTP client with interceptors
- Comprehensive error handling
- Request/response logging
- Timeout management
- Retry mechanisms

### Local Storage
- **Hive** NoSQL database
- Type-safe data models
- Fast read/write operations
- Automatic data migration

### Backend
- **Node.js + Express** RESTful API
- Deployed on **Firebase Cloud Functions**
- Scalable and serverless architecture
- Real-time API health monitoring

---

## 📋 Feature Checklist

### ✅ Implemented Features

- [x] Multi-AI model integration (Groq, Claude, GPT)
- [x] Bilingual support (English/Arabic)
- [x] Full RTL layout support
- [x] Firebase Authentication
- [x] Email/Password sign-up and login
- [x] Secure session management
- [x] Real-time chat interface
- [x] Local chat history (Hive)
- [x] AI-generated user summaries (on-demand)
- [x] Message copy functionality
- [x] Clear chat history
- [x] User profile screen
- [x] Language switcher
- [x] Theme switcher (Light/Dark/System)
- [x] Responsive design
- [x] Loading states and error handling
- [x] Localized error messages
- [x] Backend API (Node.js)
- [x] Firebase Cloud Functions deployment

### 🚧 Planned Features

- [ ] PDF chat history export
- [ ] Text file export
- [ ] Voice-to-text input
- [ ] Push notifications
- [ ] Image sharing in chat
- [ ] Group conversations
- [ ] Chat backup to cloud
- [ ] Custom AI model parameters

---

## 🎯 Use Cases

### For Students
- Quick homework help across multiple subjects
- Language translation assistance
- Research and information gathering
- Study companion with AI insights

### For Professionals
- Quick information lookup
- Draft emails and messages
- Brainstorming ideas
- Code assistance and debugging help

### For Language Learners
- Practice conversations in English or Arabic
- Real-time translation support
- Grammar and writing assistance
- Cultural insights

### For General Users
- Daily questions and curiosity
- Entertainment and conversations
- Personal assistant for tasks
- Learning new topics

---

## 🛠️ Technologies Used

### Mobile App
- **Flutter 3.16+** - Cross-platform framework
- **Dart 3.2+** - Programming language
- **Riverpod 2.4+** - State management
- **Firebase Auth** - Authentication
- **Hive 2.2+** - Local database
- **Dio 5.4+** - HTTP client
- **Easy Localization 3.0+** - Internationalization
- **Google Fonts** - Typography

### Backend
- **Node.js 18+** - Runtime environment
- **Express 4.18+** - Web framework
- **Firebase Cloud Functions** - Serverless deployment
- **Axios** - HTTP requests
- **CORS** - Cross-origin resource sharing

### AI Services
- **Groq API** - Fast LLM inference
- **OpenAI API** - GPT models
- **Anthropic API** - Claude models

---

## 📖 How to Use

### First Time Setup
1. Download and install the APK from the link above
2. Open the app
3. Select your preferred language (English or العربية)
4. Tap "Sign Up" to create a new account
5. Enter your email and password (min 6 characters)
6. Tap "Sign Up" and wait for confirmation

### Starting a Chat
1. After login, you'll see the chat screen
2. Tap the AI model selector to choose your preferred AI
3. Type your message in the input field
4. Tap the send button (➤)
5. Wait for AI response (typically 1-3 seconds)

### Generating Your Summary
1. Navigate to Profile (tap profile icon in chat screen)
2. Scroll to "User Summary" section
3. Tap "Generate Summary" button
4. Wait for AI to analyze your messages
5. View your personalized summary
6. Tap "Refresh" to regenerate with latest data

### Changing Settings
1. Go to Profile screen
2. Use the Language dropdown to switch languages
3. Use the Theme dropdown to change appearance
4. Changes apply immediately

### Clearing History
1. Go to Profile screen
2. Tap "Clear History"
3. Confirm the action
4. All messages will be deleted (cannot be undone)

---

## 🔐 Privacy & Security

- ✅ All data encrypted in transit (HTTPS)
- ✅ Passwords hashed and secured
- ✅ Local data stored securely on device
- ✅ No data sharing with third parties
- ✅ Firebase security rules implemented
- ✅ API keys securely managed
- ⚠️ Messages sent to AI services for processing
- ⚠️ AI providers may retain data per their policies

---

## ⚡ Performance

- **App Size**: ~15-20 MB (after installation)
- **Launch Time**: < 2 seconds on modern devices
- **Response Time**: 1-3 seconds (depends on AI model)
- **Memory Usage**: ~50-100 MB during active use
- **Battery Impact**: Minimal (network requests only)

---

## 🐛 Known Issues

- iOS speech-to-text requires additional setup
- Large chat histories (1000+ messages) may slow PDF export
- Translation service in beta (using AI fallback)
- Grok AI model coming soon (mock responses currently)

---

## 📞 Support & Feedback

### Found a Bug?
Please report issues with:
- Device model and OS version
- Steps to reproduce
- Screenshots if applicable
- Expected vs actual behavior

### Feature Requests
We'd love to hear your ideas! Suggest features that would make the app more useful for you.

### Contact
- **Email**: your.email@example.com
- **GitHub**: [@yourusername](https://github.com/yourusername)
- **LinkedIn**: [Your Profile](https://linkedin.com/in/yourprofile)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **ScaleX Innovation** - For the technical challenge opportunity
- **Flutter Team** - For the amazing framework
- **Firebase** - For backend services
- **OpenAI, Anthropic, Groq** - For AI API access
- **Open Source Community** - For the incredible packages

---

## 📊 Version History

### v1.0.0 (October 2024)
- 🎉 Initial release
- ✅ Multi-AI model support
- ✅ Bilingual interface (English/Arabic)
- ✅ Firebase authentication
- ✅ Chat history with local storage
- ✅ AI-generated summaries
- ✅ Theme support (Light/Dark)

---

## 🚀 Quick Links

- 📱 [Download APK](https://drive.google.com/file/d/11ZBYpsEccF89jgQVAwf1sPPaFReYQj50/view?usp=sharing)

---

**Made with ❤️ for ScaleX Innovation Technical Challenge**

*Last Updated: October 2024*
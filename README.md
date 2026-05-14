# 📱 See2Sound — App

Desktop and mobile application for **See2Sound**, an AI-powered system that transforms visual media into contextual audio descriptions.

The app is the main user-facing application where users can select videos, manage generated audio descriptions, configure accessibility options, and communicate with the backend processing service.

---

## 🎯 Purpose

The See2Sound App provides an accessible interface where users can:

- Select video files from their device
- Send videos to the backend processing API
- Access generated audio descriptions
- Manage saved audio description projects
- Configure accessibility preferences
- Use the system on desktop and mobile platforms

---

## 🧠 System Role

The app is responsible for:

- 📂 Handling local video selection
- 📤 Sending media to the backend API
- 📥 Receiving processed results
- 🎧 Displaying generated audio descriptions
- 💾 Managing saved user descriptions
- ⚙️ Providing application settings
- ♿ Offering interface accessibility options

---

## ⚙️ System Flow

```text
User
↓
See2Sound App
↓
Video Selection
↓
Backend API
↓
AI Processing Pipeline
↓
Audio Description Generation
↓
Processed Result
↓
Saved Audio Description
```

---

## 🛠 Technologies

Main technologies used:

- 💙 Flutter
- 🎯 Dart
- 🍎 iOS support
- 🖥 Windows support
- 🐧 Linux support
- 🌐 Web support
- 🔗 REST API communication

---

## 📦 Project Structure

```text
See2Sound_App/
│
├── android/                 # Android platform files
├── assets/                  # images, icons, fonts and other resources
├── ios/                     # iOS platform files
├── lib/                     # main Flutter source code
├── linux/                   # Linux platform files
├── macos/                   # macOS platform files
├── test/                    # automated tests
├── web/                     # web platform files
├── windows/                 # Windows platform files
│
├── .gitattributes
├── .gitignore
├── .metadata
├── analysis_options.yaml    # Dart/Flutter analysis rules
├── LICENSE
├── pubspec.lock
├── pubspec.yaml             # project dependencies and assets
└── README.md
```

---

## 🧩 Main App Areas

The application is planned around the following main areas:

---

### 🏠 Home

Initial screen where the user can start the process of generating audio descriptions.

This area may include:
- Main project introduction
- Button to start a new audio description
- Recent activity
- Access to main app features

---

### 📂 Video Processing

Area where the user selects a video and sends it to the backend for processing.

This area may include:
- Video file selection
- Supported format display
- Upload or processing status
- Progress feedback
- Error and success messages

---

### 🎧 Saved Audio Descriptions

Screen where generated descriptions are stored and can be accessed later.

This area may include:
- List of processed videos
- Generated audio description history
- Access to previous results
- File information
- Options to open, delete or manage descriptions

---

### ⚙️ Settings

Application configuration screen, including accessibility preferences.

This area may include:
- Theme options
- High contrast mode
- Interface audio description toggle
- Narration-related options
- Visual effect reduction
- General app preferences

---

### ♿ Accessibility

Accessibility is one of the central goals of the app.

The application aims to support:
- Screen reader compatibility
- Keyboard navigation
- High contrast mode
- Clear visual hierarchy
- Audio description for the interface
- Options to reduce visual effects
- Accessible controls and navigation patterns
- Consistent focus indicators

---

### 🔗 Backend Communication

The app communicates with the See2Sound backend through API requests.

Main communication responsibilities include:
- Sending selected video files
- Receiving processing status
- Receiving generated audio description data
- Accessing processed media or narration results
- Handling errors during communication
- Displaying processing feedback to the user

---

## 🧪 Testing

Testing may include:
- Widget tests
- Unit tests
- Interface behavior tests
- API communication tests
- Accessibility-related tests
- Platform compatibility tests

---

## 🚧 Development Status

🚧 Project currently under development as part of the See2Sound Project.

---

## 🎯 Future Goals

- Improve desktop and mobile layout
- Integrate complete backend communication
- Add saved description management
- Improve accessibility options
- Support multiple video formats
- Add progress tracking during processing
- Improve user experience for long video files
- Add better error handling
- Improve platform-specific builds

---

## ❤️ Accessibility First

See2Sound is built with a focus on digital accessibility, helping visually impaired users access visual media through contextual audio descriptions.
The application is designed to be the main bridge between the user and the See2Sound processing system.

---

## 🔗 Related Repositories

This project is part of the See2Sound system.
- 🌐 Frontend Website → https://github.com/ClarAlvez/See2Sound_Frontend
- 🧠 Backend AI/API → https://github.com/ClarAlvez/See2Sound_Backend

---

## 👨‍💻 Authors

Developed as part of the **See2Sound Project**.

- 💫​ Clara Alves dos Santos — [GitHub](https://github.com/ClarAlvez)
- 🐶​​ João Victor Cussolim   — [GitHub](https://github.com/JoaoCussolim)

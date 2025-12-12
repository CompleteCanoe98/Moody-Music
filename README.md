# Moody Music

A music app built with Flutter that plays songs based on your mood.

-In Progress, not Available for Android yet- 

## 📱 How to Run on iOS

Because this is a Flutter project, you will need the Flutter SDK installed on your Mac to build the app.

### Prerequisites
* **Hardware:** A Mac computer (macOS is required to build iOS apps).
* **Software:**
    * [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) installed.
    * **Xcode** installed (from the Mac App Store).
    * **CocoaPods** (install via Homebrew if homebrew is installed: `brew install cocoapods`).

### Installation Steps

1.  **Clone the Repository**
    Open your terminal and run:
    ```bash
    git clone https://github.com/CompleteCanoe98/Moody-Music.git
    cd Moody-Music
    ```

2.  **Install Flutter Dependencies**
    Download the required libraries:
    ```bash
    flutter pub get
    ```

3.  **Install iOS Pods (Important)**
    Navigate to the iOS folder to install native dependencies:
    ```bash
    cd ios
    pod install
    cd ..
    ```

4.  **Open in Xcode for Signing & Config**
    * Open the file `ios/Runner.xcworkspace` in Xcode (do not open `.xcodeproj`).
    * Click on **Runner** in the left sidebar.
    * Select the **Signing & Capabilities** tab.
    * **Team:** Select your Apple ID (Add Account if needed).
    * **Bundle Identifier:** Ensure this matches the Redirect URI you set in the Spotify Developer Dashboard (e.g., `com.yourname.moodymusic`).

5.  **Run the App**
    You can run it directly from your terminal:
    ```bash
    flutter run
    ```
    *Ensure your iPhone is connected via USB and unlocked.*

---



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

## Spotify Developer Setup
Since this app uses the Spotify SDK, you will need your own credentials to run it.

1.  Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and log in.
2.  Click **Create App** and give it a name (e.g., "Moody Music Local").
3.  In the app settings, find **Bundle IDs** (or "Redirect URIs" for iOS).
4.  Add the **Bundle Identifier** you used in Xcode (e.g., `com.yourname.moodymusic`).
5.  Add the Redirect URI: `moody-music://callback` (or whatever you defined in your `Info.plist`).
6.  Save the settings.
7.  Copy the **Client ID** and **Redirect URI**.

### Adding Keys to the App
1.  Create a file named `.env` (or look for `secrets.dart` if you used that method) in the root directory.
2.  Paste your keys there:
    ```
    SPOTIFY_CLIENT_ID=your_client_id_here
    SPOTIFY_REDIRECT_URI=your_redirect_uri_here
    ```


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
    * **Bundle Identifier:** You may need to change this to something unique to avoid conflicts (e.g., change com.original.app to com.yourname.moodymusic). Whatever you put in the spotify dashboard.

5. ## Running the App

  **Connect your iPhone** via USB to your Mac.
  **Unlock the phone** and ensure **Developer Mode** is turned **On**.
    * *Go to: Settings > Privacy & Security > Developer Mode.*
  In Xcode, **select your connected iPhone** from the device list (top center of the window).
  Press the **Play** button (top left) or press `Cmd + R` to build and run the app.

### Troubleshooting: "Untrusted Developer" Error
If the app installs successfully but fails to launch with a security popup on your iPhone:

1.  On your iPhone, go to **Settings > General > VPN & Device Management**.
2.  Tap the profile matching your Apple ID email (under "Developer App").
3.  Tap **Trust [Your Email]**.
4.  Launch the app again.

---

---



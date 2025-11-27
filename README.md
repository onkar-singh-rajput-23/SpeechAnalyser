## Note Taker

## Installation
1. clone the repo 
2. go to the .xcoproject file and open XCode should be installed and targeted verion should be IOS 26+


## Architecture 

The app is designed following a clean architecture pattern MVVM, which consists of the following layers:

- **Models**: Represent the data structures, such as `Transcript` and `RecordingMetadata`.
- **ViewModels**: Handle business logic and state management. Example: `TranscriptionViewModel`.
- **Views**: Comprise SwiftUI views and components for user interaction.
  ##  Helper Layers 
- **Services**: Provide core functionality like transcription, text analysis, and audio processing.
- **Persistence**: Serve as the data storage layer using a file-based repository.

### Key Components

#### TranscriptionViewModel

- Manages the recording state.
- Handles editing and persistence of transcripts.
- Acts as a coordinator between services and views.
- Maintains transcript history.

#### TranscriptionService

- Utilizes the `Speech` framework for speech recognition.
- Manages audio recording.
- Provides real-time transcription events using on-device processing.
- I have't use IOS 26+ SpeechAnalyzer due to Hardware issues.

#### TextAnalyzer

- Performs automatic punctuation insertion and capitalization fixes.
- Cleans and formats text.
- Detects language.

#### FileStorageRepository

- Stores data in JSON format.
- Includes CRUD operations for transcripts.
- Sorts transcripts by creation date automatically.

## Usage 

### Recording a Transcript

1. Tap the record button (glass circle at the bottom).
2. Speak your notes and watch real-time transcription.
3. Tap the button again to stop recording.

### Editing Transcripts

1. Tap "Tap to Edit" on any transcript.
2. Edit the transcript in the text editor.
3. Tap "Save Changes" to save your edits.

### Managing History

- **View Details**: Tap any transcript in the history section.
- **Delete**: Swipe to delete or use the delete action (if implemented).
- **Refresh**: Tap the refresh button in the toolbar.

### Intelligent Analysis

Toggle the AI Analysis switch in the toolbar to enable/disable:
- Automatic punctuation
- Capitalization fixes
- Text cleanup

## Permissions 

The app requests the following permissions:

- **Microphone**: Needed to record audio for transcription.
- **Speech Recognition**: Needed to convert speech to text.

Permissions are requested automatically on first use.

## Data Storage

Transcripts are stored locally on the device in JSON format:

- All data remains on the device, ensuring privacy as nothing is sent to external servers.

## Technologies Used 

- **SwiftUI**: For modern declarative UI design.
- **Speech Framework**: For on-device speech recognition.
- **AVFoundation**: For audio recording and playback.
- **NaturalLanguage**: For text analysis and processing.
- **Combine**: For reactive programming and handling events.
- **FileManager**: For local file storage management.

## Design Philosophy 

- **Privacy First**: Processes all data on-device.
- **Modern UI**: Utilizes a glass morphism design with smooth animations.
- **User Experience**: Ensures an intuitive interface with real-time feedback.
- **Performance**: Designed for efficient memory and CPU usage.

## Future Enhancements 

Potential future features include:

- Adding IOS 26+ SpeechAnalyzer to correct and anlyse the sentences PDF correction.
- Enhanced real time Spech recognition UI 

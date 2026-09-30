# Audio & Video App (Flutter + Flask)

A mobile app to record audio, play it, upload it to a Flask server, and play videos.

## Versions
- Flutter 3.x / Dart 3.x (check with `flutter --version`)
- Python 3.10+, Flask 3.0.3, Flask-SQLAlchemy 3.1.1, mutagen 1.47

## Project Structure
```
audio_video_app/
├── backend/   (Flask REST API + SQLite)
└── frontend/  (Flutter app)
```

## How to run

### Backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
python run.py                # http://localhost:5000
python -m pytest tests -v    # 9 tests
```
Database setup: nothing to do. SQLite tables (`audio`, `video`) are created automatically on first run.

### Flutter
```bash
cd frontend
flutter pub get
flutter run
flutter test
```
Set the server address in `lib/constants.dart`:
emulator `http://10.0.2.2:5000`, real phone `http://<laptop-ip>:5000` (same Wi-Fi).

## Features
- Record audio (start, pause, resume, stop) with a live timer
- Save recordings on the phone and list them
- Play audio: play/pause, seek bar, **playback speed (0.5x-2x) and volume control**
- Upload recordings to Flask (with progress bar), list uploaded audio and play it from the server
- Video list, upload from gallery, video player with play/pause, seek, duration, volume, fullscreen
- Handles permission denied, loading, empty and error states

## Architecture (Flutter)
I used a **simple layered structure with setState**:
```
lib/
├── main.dart          (entry point only)
├── constants.dart     (server address)
├── models/            (MediaItem)
├── services/          (ApiService: all Dio calls)
├── screens/           (one file per screen)
└── utils/             (helpers)
```
**Why:** the app is small and I wanted code that is easy to read and explain. Screens do not call the
network directly. They use `ApiService`, so UI and API code stay separate. For a bigger app I would move to
Clean Architecture with Provider or BLoC.

Flask: `routes` (URLs) -> `services` (validation, file handling) -> `models` (SQLAlchemy) + `uploads/` folder.

## Libraries
| Library | Use |
|---|---|
| record | audio recording |
| just_audio | audio playback, speed, volume |
| video_player + chewie | video playback UI (seek, fullscreen) |
| dio | HTTP calls, upload progress, timeouts |
| permission_handler | microphone permission |
| path_provider | app storage folder |
| image_picker | choose a video from gallery |

## API
| Method | Endpoint | Purpose | Errors |
|---|---|---|---|
| GET | /api/health | Health check | - |
| POST | /api/audio/upload | Upload audio (form field `file`) | 400, 413, 415, 422 |
| GET | /api/audio | List audio | - |
| GET | /api/audio/<id> | Stream / download | 404 |
| DELETE | /api/audio/<id> | Delete | 404 |
| POST | /api/videos/upload | Upload video | 400, 413, 415 |
| GET | /api/videos | List videos | - |
| GET | /api/videos/<id> | Stream / download | 404 |
| DELETE | /api/videos/<id> | Delete | 404 |

Upload response: `{"status":"success","message":"Audio uploaded successfully","file_id":"1","file_url":"/api/audio/1"}`
Error response: `{"status":"error","message":"..."}`

## Database
SQLite with SQLAlchemy. Tables `audio` and `video`: id, file_name, file_path, duration, file_size, created_at.
Only metadata is in the database. Files are stored in `backend/uploads/`.

## Security
Allowed file types only, 200 MB size limit, server-generated file names (no client paths), corrupted audio rejected.

## Testing
- Flask: 9 pytest tests (health, upload, list, stream + range, delete, bad type, corrupted file, size limit, video)
- Flutter: unit tests (time format, JSON parsing), API integration test with a fake Dio, widget tests for Home and Video list

## Known limitations
- No login/authentication
- Recording flow and video playback need a real device, so they were tested manually, not in unit tests
- Video type is checked by extension only; audio is also parsed by mutagen
- List APIs have no pagination
- Android only

## Future improvements
JWT authentication, pagination, Docker, waveform, video thumbnails, background upload, Clean Architecture with Provider/BLoC.

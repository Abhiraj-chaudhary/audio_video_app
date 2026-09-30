# Flask Backend - Audio & Video API

**Versions:** Python 3.10+, Flask 3.0.3, Flask-SQLAlchemy 3.1.1, mutagen 1.47

## Setup
```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python run.py                   # http://localhost:5000
```
**Database:** SQLite (`media.db`). Tables `audio` and `video` are created automatically on first run
(`db.create_all()`). Columns: id, file_name, file_path, duration, file_size, created_at.
Only metadata is stored in the DB; media files live in `uploads/audio` and `uploads/video`.

## Tests
```bash
python -m pytest tests -v
```

## API
| Method | Endpoint | Purpose | Errors |
|---|---|---|---|
| GET | /api/health | Health check | - |
| POST | /api/audio/upload | Upload audio (multipart field `file`) | 400, 413, 415, 422 |
| GET | /api/audio?q=name | List / search audio | - |
| GET | /api/audio/<id> | Stream/download (supports Range) | 404 |
| DELETE | /api/audio/<id> | Delete audio | 404 |
| POST | /api/videos/upload | Upload video (`file`, optional `duration`) | 400, 413, 415 |
| GET | /api/videos | List / search videos | - |
| GET | /api/videos/<id> | Stream/download (supports Range) | 404 |
| DELETE | /api/videos/<id> | Delete video | 404 |

Upload response (201):
```json
{"status":"success","message":"Audio uploaded successfully","file_id":"1","file_url":"/api/audio/1"}
```
Error response: `{"status":"error","message":"..."}`

## Security
- Only whitelisted extensions; 200 MB size limit (HTTP 413)
- Files are stored under server-generated UUID names; clients never supply paths
- Corrupted audio is rejected (422)

import io
import wave


def make_wav(seconds=1):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(8000)
        w.writeframes(b"\x00\x00" * 8000 * seconds)
    buf.seek(0)
    return buf


def upload_audio(client, name="test.wav"):
    return client.post("/api/audio/upload",
                       data={"file": (make_wav(2), name)},
                       content_type="multipart/form-data")


def test_health(client):
    r = client.get("/api/health")
    assert r.status_code == 200 and r.get_json()["status"] == "ok"


def test_upload_audio(client):
    r = upload_audio(client)
    body = r.get_json()
    assert r.status_code == 201
    assert body["status"] == "success"
    assert body["file_url"] == f"/api/audio/{body['file_id']}"


def test_list_audio(client):
    upload_audio(client)
    r = client.get("/api/audio")
    items = r.get_json()["items"]
    assert r.status_code == 200 and len(items) == 1
    assert items[0]["duration"] == 2


def test_stream_audio_and_range(client):
    fid = upload_audio(client).get_json()["file_id"]
    assert client.get(f"/api/audio/{fid}").status_code == 200
    r = client.get(f"/api/audio/{fid}", headers={"Range": "bytes=0-99"})
    assert r.status_code == 206   # seeking supported


def test_delete_audio(client):
    fid = upload_audio(client).get_json()["file_id"]
    assert client.delete(f"/api/audio/{fid}").status_code == 200
    assert client.get(f"/api/audio/{fid}").status_code == 404


def test_reject_bad_type(client):
    r = client.post("/api/audio/upload",
                    data={"file": (io.BytesIO(b"x"), "evil.exe")},
                    content_type="multipart/form-data")
    assert r.status_code == 415


def test_reject_corrupted_audio(client):
    r = client.post("/api/audio/upload",
                    data={"file": (io.BytesIO(b"not audio"), "bad.mp3")},
                    content_type="multipart/form-data")
    assert r.status_code == 422


def test_missing_file_and_too_large(client):
    assert client.post("/api/audio/upload").status_code == 400
    big = io.BytesIO(b"0" * (2 * 1024 * 1024))
    r = client.post("/api/audio/upload", data={"file": (big, "a.mp3")},
                    content_type="multipart/form-data")
    assert r.status_code == 413


def test_video_upload_list_delete(client):
    r = client.post("/api/videos/upload",
                    data={"file": (io.BytesIO(b"\x00" * 100), "clip.mp4"), "duration": "12"},
                    content_type="multipart/form-data")
    assert r.status_code == 201
    vid = r.get_json()["file_id"]
    assert client.get("/api/videos").get_json()["items"][0]["duration"] == 12
    assert client.get(f"/api/videos/{vid}").status_code == 200
    assert client.delete(f"/api/videos/{vid}").status_code == 200

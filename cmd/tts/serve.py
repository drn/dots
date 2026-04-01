"""Kokoro TTS daemon — keeps model warm, serves requests via Unix socket."""
import io
import json
import os
import signal
import socket
import struct
import sys
import time
import warnings

warnings.filterwarnings("ignore")
os.environ["HF_HUB_OFFLINE"] = "1"

SOCK_PATH = "/tmp/kokoro-tts.sock"
PID_PATH = "/tmp/kokoro-tts.pid"
MAX_REQUEST = 65536


def main():
    if os.path.exists(SOCK_PATH):
        if os.path.exists(PID_PATH):
            try:
                pid = int(open(PID_PATH).read().strip())
                os.kill(pid, 0)
                print(f"Daemon already running (pid {pid})", file=sys.stderr)
                sys.exit(1)
            except (OSError, ValueError):
                pass
        os.unlink(SOCK_PATH)

    with open(PID_PATH, "w") as f:
        f.write(str(os.getpid()))

    t0 = time.time()
    import numpy as np
    import soundfile as sf
    from kokoro import KPipeline

    pipeline = KPipeline(lang_code="a")
    print(f"Model loaded in {time.time() - t0:.1f}s", flush=True)
    print(f"Listening on {SOCK_PATH}", flush=True)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCK_PATH)
    os.chmod(SOCK_PATH, 0o600)
    server.listen(5)

    def shutdown(sig=None, frame=None):
        server.close()
        for path in (SOCK_PATH, PID_PATH):
            try:
                os.unlink(path)
            except OSError:
                pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            break
        try:
            data = b""
            while not data.endswith(b"\n"):
                if len(data) > MAX_REQUEST:
                    break
                chunk = conn.recv(4096)
                if not chunk:
                    break
                data += chunk

            req = json.loads(data.strip())
            text = req["text"]
            voice = req.get("voice", "af_heart")
            speed = float(req.get("speed", 1.0))

            chunks = [
                audio
                for _, _, audio in pipeline(text, voice=voice, speed=speed)
            ]
            audio = np.concatenate(chunks)

            buf = io.BytesIO()
            sf.write(buf, audio, 24000, format="WAV")
            wav_bytes = buf.getvalue()

            conn.sendall(b"\x00" + struct.pack(">I", len(wav_bytes)) + wav_bytes)
        except Exception as e:
            err_msg = str(e).encode("utf-8")
            try:
                conn.sendall(b"\x01" + struct.pack(">I", len(err_msg)) + err_msg)
            except OSError:
                pass
        finally:
            conn.close()

    shutdown()


if __name__ == "__main__":
    main()

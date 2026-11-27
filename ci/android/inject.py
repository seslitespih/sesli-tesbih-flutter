# -*- coding: utf-8 -*-
"""Streams a WAV into the Android emulator's virtual microphone in real time
(emulator gRPC `injectAudio`). Usage: inject.py file.wav [port]"""
import os, sys, time, wave, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, 'gen')
if not os.path.exists(os.path.join(GEN, 'emulator_controller_pb2_grpc.py')):
    os.makedirs(GEN, exist_ok=True)
    import grpc_tools
    inc = os.path.join(os.path.dirname(grpc_tools.__file__), '_proto')
    subprocess.check_call([sys.executable, '-m', 'grpc_tools.protoc', f'-I{HERE}', f'-I{inc}',
                           f'--python_out={GEN}', f'--grpc_python_out={GEN}',
                           os.path.join(HERE, 'emulator_controller.proto')])
sys.path.insert(0, GEN)
import grpc
import emulator_controller_pb2 as pb
import emulator_controller_pb2_grpc as rpc

wav_path = sys.argv[1]
port = sys.argv[2] if len(sys.argv) > 2 else '8554'

with wave.open(wav_path, 'rb') as w:
    assert w.getnchannels() == 1 and w.getsampwidth() == 2
    sr = w.getframerate()
    pcm = w.readframes(w.getnframes())

FRAME_MS = 20
frame_bytes = int(sr * FRAME_MS / 1000) * 2
fmt = pb.AudioFormat(samplingRate=sr, channels=pb.AudioFormat.Mono,
                     format=pb.AudioFormat.AUD_FMT_S16, mode=pb.AudioFormat.MODE_REAL_TIME)


LAG = []


def packets():
    t0 = time.perf_counter()
    for i in range(0, len(pcm), frame_bytes):
        chunk = pcm[i:i + frame_bytes]
        if len(chunk) < frame_bytes:
            chunk += b'\x00' * (frame_bytes - len(chunk))
        # keep a constant real-time rate (the emulator requires it)
        due = t0 + (i // frame_bytes) * FRAME_MS / 1000.0
        delay = due - time.perf_counter()
        if delay > 0:
            time.sleep(delay)
        else:
            LAG.append(-delay)
        yield pb.AudioPacket(format=fmt, timestamp=int(time.time() * 1e6), audio=chunk)


ch = grpc.insecure_channel(f'127.0.0.1:{port}')
stub = rpc.EmulatorControllerStub(ch)
print(f'injecting {wav_path}: {len(pcm)/2/sr:.1f}s @ {sr} Hz', flush=True)
stub.injectAudio(packets())
late = [l for l in LAG if l > 0.1]
print(f'inject done  late>100ms={len(late)} max_lag={max(LAG) * 1000 if LAG else 0:.0f}ms', flush=True)

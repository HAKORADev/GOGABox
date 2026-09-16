#!/usr/bin/env python3
"""v040-3 THE ACTION SONG - render the original's AtomicTank.mo3 (the
PopCap module format, IT-compressed) to WAV via libopenmpt (already on the
rig), then hand it to ffmpeg for the game's ogg. The owner: 'the game song
is one song part and it is bad, there is other songs in the original game
too which are better and more action-focused' - this IS the other song.
"""
import ctypes
import ctypes.util
import sys
import struct
import wave

MO3 = "/home/z/my-project/v040_2_study/hw_orig/HeavyWeapon/Music/AtomicTank.mo3"
WAV = "/tmp/hws_atomictank.wav"

lib = ctypes.CDLL("libopenmpt.so.0")

# openmpt_module_create_from_memory2(data, size, logfunc, user, errfunc,
#                                   erruser, error, errorlen)
lib.openmpt_module_create_from_memory2.restype = ctypes.c_void_p
lib.openmpt_module_create_from_memory2.argtypes = [
        ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_void_p,
        ctypes.c_void_p, ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t]
lib.openmpt_module_read_interleaved_stereo.restype = ctypes.c_size_t
lib.openmpt_module_read_interleaved_stereo.argtypes = [
        ctypes.c_void_p, ctypes.c_int32, ctypes.c_size_t,
        ctypes.POINTER(ctypes.c_float)]
lib.openmpt_module_destroy.restype = None
lib.openmpt_module_destroy.argtypes = [ctypes.c_void_p]
lib.openmpt_module_get_duration_seconds.restype = ctypes.c_double
lib.openmpt_module_get_duration_seconds.argtypes = [ctypes.c_void_p]
lib.openmpt_module_set_repeat_count.restype = None
lib.openmpt_module_set_repeat_count.argtypes = [ctypes.c_void_p, ctypes.c_int32]

data = open(MO3, "rb").read()
buf = ctypes.create_string_buffer(data, len(data))
# openmpt_module_create_from_memory(data, size, logfunc, user, ctls=NULL)
lib.openmpt_module_create_from_memory.restype = ctypes.c_void_p
lib.openmpt_module_create_from_memory.argtypes = [
        ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_void_p,
        ctypes.c_void_p]
mod = lib.openmpt_module_create_from_memory(
        ctypes.cast(buf, ctypes.c_void_p), len(data), None, None, None)
if not mod:
        print("RENDER FAIL: openmpt could not open the module")
        sys.exit(1)
lib.openmpt_module_set_repeat_count(mod, 0)   # play through once
dur = lib.openmpt_module_get_duration_seconds(mod)
print(f"module opens: {dur:.1f}s")

SR = 44100
CHUNK = 4096
total = int(dur * SR) + SR
out = wave.open(WAV, "wb")
out.setnchannels(2)
out.setsampwidth(2)
out.setframerate(SR)
arr = (ctypes.c_float * (CHUNK * 2))()
done = 0
while done < total:
        got = lib.openmpt_module_read_interleaved_stereo(
                mod, SR, CHUNK, arr)
        if got == 0:
                break
        frames = bytes(arr)[:got * 2 * 2]   # float32 -> we asked c_float but
        # read_interleaved_stereo returns float32; convert to int16
        import array
        f32 = array.array("f")
        f32.frombytes(bytes(arr)[:got * 8])
        i16 = array.array("h")
        import math
        for v in f32:
                if not math.isfinite(v):
                        v = 0.0
                s = int(v * 32767.0)
                i16.append(max(-32768, min(32767, s)))
        out.writeframes(i16.tobytes())
        done += got
out.close()
lib.openmpt_module_destroy(mod)
print(f"RENDER OK: {WAV} ({done/SR:.1f}s)")

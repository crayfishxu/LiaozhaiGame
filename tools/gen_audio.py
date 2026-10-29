#!/usr/bin/env python3
"""《聊斋美人》音频生成器。

全部音频由本脚本程序化合成，不依赖任何外部素材，因此没有版权问题。
风格约束：冷、静、克制。用五声音阶（D 羽调式）、拨弦、钟、木鱼、风。

用法：
    python tools/gen_audio.py bgm     # 只生成三首 BGM
    python tools/gen_audio.py sfx     # 只生成音效
    python tools/gen_audio.py all     # 全部（默认）

输出：
    audio/bgm/*.ogg   循环音乐（Vorbis，体积小）
    audio/sfx/*.wav   短音效（16bit 单声道，无压缩延迟）
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BGM_DIR = os.path.join(ROOT, "audio", "bgm")
SFX_DIR = os.path.join(ROOT, "audio", "sfx")

# ---------------------------------------------------------------- 音高

def note(name: str) -> float:
    """音名 → 频率，如 D3 / A#4。"""
    table = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
             "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    name = name.replace("b", "S")
    if "S" in name:                      # 降号：相邻半音减一
        base, octv = name.split("S")
        semi = table[base] - 1
    else:
        base, octv = name[:-1], name[-1]
        semi = table[base]
    midi = 12 * (int(octv) + 1) + semi
    return 440.0 * 2 ** ((midi - 69) / 12)


def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


# ---------------------------------------------------------------- 乐器

def pluck(freq: float, dur: float, bright: float = 0.55, decay: float = 2.2,
          attack: float = 0.012, seed: int = 0) -> np.ndarray:
    """拨弦：加性谐波 + 起音噪声。音准精确，音色偏古琴。"""
    t = t_axis(dur)
    rng = np.random.default_rng(seed)
    out = np.zeros_like(t)
    n_harm = 14
    for h in range(1, n_harm + 1):
        f = freq * h
        if f > SR * 0.45:
            break
        amp = (1.0 / h ** 1.15) * (bright ** (h - 1))
        d = decay * (1 + 0.55 * (h - 1))
        out += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28) * 0.15) * np.exp(-d * t)
    # 拨片噪声：极短，带通感
    n_len = int(attack * 4 * SR)
    if n_len > 8:
        noise = rng.normal(0, 1, n_len)
        noise = np.convolve(noise, np.ones(6) / 6, "same")
        env = np.exp(-np.arange(n_len) / (attack * SR))
        out[:n_len] += noise * env * 0.16
    # 起音包络，避免爆音
    a = max(4, int(0.004 * SR))
    out[:a] *= np.linspace(0, 1, a)
    return out


def bell(freq: float, dur: float, decay: float = 1.1, seed: int = 0) -> np.ndarray:
    """钟：非谐波泛音，长衰减。"""
    t = t_axis(dur)
    rng = np.random.default_rng(seed)
    partials = [(1.0, 1.00, 1.00), (2.0, 0.55, 1.25), (2.76, 0.42, 1.55),
                (4.07, 0.24, 2.10), (5.40, 0.18, 2.60), (8.93, 0.10, 3.40)]
    out = np.zeros_like(t)
    for ratio, amp, dscale in partials:
        f = freq * ratio
        if f > SR * 0.45:
            continue
        out += (amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 0.4))
                * np.exp(-decay * dscale * t))
    a = max(4, int(0.003 * SR))
    out[:a] *= np.linspace(0, 1, a)
    return out


def woodblock(dur: float = 0.18, freq: float = 620.0, seed: int = 0) -> np.ndarray:
    """木鱼：短促、干脆。"""
    t = t_axis(dur)
    rng = np.random.default_rng(seed)
    body = np.sin(2 * np.pi * freq * t) * np.exp(-22 * t)
    body += np.sin(2 * np.pi * freq * 1.62 * t) * np.exp(-30 * t) * 0.4
    noise = rng.normal(0, 1, len(t))
    noise = np.convolve(noise, np.ones(3) / 3, "same") * np.exp(-70 * t) * 0.55
    out = body * 0.7 + noise
    a = max(4, int(0.001 * SR))
    out[:a] *= np.linspace(0, 1, a)
    return out


def drum(dur: float = 0.5, f0: float = 96.0, f1: float = 46.0, seed: int = 0) -> np.ndarray:
    """低鼓：音高下扫 + 闷噪。"""
    t = t_axis(dur)
    rng = np.random.default_rng(seed)
    f = f0 * (f1 / f0) ** (t / dur)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-6.5 * t)
    noise = rng.normal(0, 1, len(t))
    noise = np.convolve(noise, np.ones(9) / 9, "same") * np.exp(-24 * t) * 0.28
    out = body + noise
    a = max(4, int(0.002 * SR))
    out[:a] *= np.linspace(0, 1, a)
    return out


def wind(dur: float, seed: int = 1, cutoff: int = 40) -> np.ndarray:
    """风：低通白噪声 + 缓慢起伏。"""
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    noise = rng.normal(0, 1, n)
    # 多级移动平均近似低通
    k = np.ones(cutoff) / cutoff
    out = np.convolve(noise, k, "same")
    out = np.convolve(out, k, "same")
    t = np.arange(n) / SR
    # 两个不同周期的 LFO 叠加，避免听出规律
    lfo = 0.55 + 0.28 * np.sin(2 * np.pi * t / 11.0) + 0.17 * np.sin(2 * np.pi * t / 4.3 + 1.2)
    return out * lfo


def drone(freqs, dur: float, amp: float = 0.2, seed: int = 2) -> np.ndarray:
    """低频铺底：正弦叠加 + 轻微失谐 + 慢抖动。"""
    t = t_axis(dur)
    out = np.zeros_like(t)
    rng = np.random.default_rng(seed)
    for i, f in enumerate(freqs):
        det = 1.0 + rng.uniform(-0.0016, 0.0016)
        depth = 0.10 + 0.05 * i
        lfo = 1.0 + depth * np.sin(2 * np.pi * t / (7.0 + 1.5 * i) + rng.uniform(0, 6.28))
        out += np.sin(2 * np.pi * f * det * t) * lfo * (0.65 ** i)
    return out * amp


# ---------------------------------------------------------------- 效果

def reverb(x: np.ndarray, seconds: float = 1.6, mix: float = 0.32, seed: int = 7) -> np.ndarray:
    """指数衰减噪声脉冲响应卷积。"""
    from scipy.signal import fftconvolve
    n = int(seconds * SR)
    rng = np.random.default_rng(seed)
    ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (seconds * SR * 0.32))
    ir[: int(0.012 * SR)] = 0            # 预延迟
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = fftconvolve(x, ir, mode="full")[: len(x)]
    return x * (1 - mix) + wet * mix * 1.8


def loop_wrap(x: np.ndarray, tail: float = 2.2) -> np.ndarray:
    """等功率交叉淡化，把尾部折回开头，做出无缝循环。

    保证 out[0] == 原信号 x[-n]（尾段起点），out[-1] == x[-n-1]，
    两者在原信号里本来就是相邻样本，所以循环接缝连续。
    """
    n = int(tail * SR)
    if n * 2 >= len(x):
        return x
    body = x[:-n].copy()
    head = x[:n]
    tailseg = x[-n:]
    # 开方交叉：能量恒定，避免中间塌陷
    f = np.linspace(0.0, 1.0, n) ** 0.5
    body[:n] = head * f + tailseg * (1.0 - f)
    return body


def soft_limit(x: np.ndarray, peak: float = 0.89) -> np.ndarray:
    """软限幅 + 归一化，保证不削波。"""
    x = np.nan_to_num(x, nan=0.0, posinf=0.0, neginf=0.0)
    x = x - np.mean(x)
    m = np.max(np.abs(x))
    if m < 1e-9:
        return x
    x = x / m
    x = np.tanh(x * 1.15) / np.tanh(1.15)
    return x * peak


def stereo(x: np.ndarray, width: float = 0.12) -> np.ndarray:
    """单声道 → 轻微立体声。

    右声道用**循环移位**而不是补零延迟——补零会在右声道开头留下几毫秒静音，
    循环播放时每一圈都会断一下；循环移位则保持波形首尾相接。
    """
    d = int(0.008 * SR * width / 0.12)
    left = x
    right = np.roll(x, d) * 0.96
    return np.stack([left, right], axis=1)


# ---------------------------------------------------------------- 写入

def write_wav(path: str, data: np.ndarray) -> None:
    if data.ndim == 1:
        data = data[:, None]
    pcm = np.clip(data, -1, 1)
    pcm = (pcm * 32767).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as f:
        f.setnchannels(pcm.shape[1])
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


def to_ogg(wav_path: str, ogg_path: str, quality: int = 4) -> bool:
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
           "-c:a", "libvorbis", "-q:a", str(quality), ogg_path]
    try:
        subprocess.run(cmd, check=True)
        return True
    except Exception as exc:                       # noqa: BLE001
        print(f"    ! ogg 转换失败: {exc}")
        return False


def stats(name: str, x: np.ndarray) -> None:
    mono = x if x.ndim == 1 else x.mean(axis=1)
    peak = float(np.max(np.abs(mono)))
    rms = float(np.sqrt(np.mean(mono ** 2)))
    dur = len(mono) / SR
    print(f"    {name}: {dur:5.1f}s  peak {peak:.2f}  rms {rms:.3f}")


# ---------------------------------------------------------------- 编曲工具

class Track:
    """按时间轴叠加音符。"""

    def __init__(self, dur: float):
        self.buf = np.zeros(int(dur * SR) + SR * 3)   # 留尾巴

    def add(self, sig: np.ndarray, at: float, gain: float = 1.0) -> None:
        i = int(at * SR)
        end = min(i + len(sig), len(self.buf))
        if end <= i:
            return
        self.buf[i:end] += sig[: end - i] * gain

    def done(self, dur: float) -> np.ndarray:
        n = int(dur * SR)
        return self.buf[:n]


# ---------------------------------------------------------------- BGM

def make_layer1() -> np.ndarray:
    """第一层 · 外院：稀疏、清冷。54 BPM，8 小节 ≈ 35.6s。"""
    bpm = 54.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    tr = Track(dur + 3)

    # 铺底：D2 + A2（空五度）
    tr.add(drone([note("D2"), note("A2")], dur + 2.5, amp=0.26), 0.0)
    # 风
    tr.add(wind(dur + 2.5, seed=11) * 0.10, 0.0)

    # 旋律：D 羽调式，稀疏
    melody = [
        (0.0, "D4", 0.55), (1.5, "F4", 0.42), (3.0, "A3", 0.38),
        (4.5, "C4", 0.40), (6.0, "D4", 0.44),
        (8.0, "A3", 0.40), (9.5, "C4", 0.36), (11.0, "D4", 0.34),
        (12.5, "F4", 0.30), (14.0, "A4", 0.26),
    ]
    for i, (b, n, g) in enumerate(melody):
        tr.add(pluck(note(n), 2.6, bright=0.52, decay=1.5, seed=i), b * beat, g)

    # 低音支点
    for b in (0.0, 8.0, 16.0):
        tr.add(pluck(note("D2"), 3.4, bright=0.35, decay=1.1, seed=90 + int(b)), b * beat, 0.30)

    # 钟：每 4 小节一次
    tr.add(bell(note("D4"), 6.0, decay=0.55, seed=3), 0.0, 0.16)
    tr.add(bell(note("A3"), 6.0, decay=0.55, seed=4), 16 * beat, 0.13)

    out = tr.done(dur)
    out = reverb(out, 2.4, 0.34, seed=5)
    return out


def make_layer2() -> np.ndarray:
    """第二层 · 佛堂：木鱼、更低的铺底、压迫感。66 BPM，8 小节 ≈ 29s。"""
    bpm = 66.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    tr = Track(dur + 3)

    # 铺底：D2 + F2（小三度，暗）
    tr.add(drone([note("D2"), note("F2"), note("D3")], dur + 2.5, amp=0.24), 0.0)
    tr.add(wind(dur + 2.5, seed=21) * 0.06, 0.0)

    # 木鱼：稳定四分音符，第 4、8 小节留白
    for b in range(bars * 4):
        bar = b // 4
        if bar in (3, 7):
            continue
        accent = 0.16 if b % 4 == 0 else 0.10
        tr.add(woodblock(seed=100 + b), b * beat, accent)

    # 低鼓：每小节头
    for bar in range(bars):
        tr.add(drum(f0=88, f1=44, seed=200 + bar), bar * 4 * beat, 0.30)

    # 旋律：低音区，密集些
    melody = [
        (0.0, "D3", 0.50), (2.0, "F3", 0.40), (4.0, "G3", 0.36), (6.0, "A3", 0.32),
        (8.0, "F3", 0.40), (10.0, "D3", 0.36), (12.0, "C3", 0.30),
        (16.0, "A3", 0.34), (18.0, "G3", 0.30), (20.0, "F3", 0.28),
        (24.0, "D3", 0.38), (26.0, "C3", 0.30),
    ]
    for i, (b, n, g) in enumerate(melody):
        tr.add(pluck(note(n), 2.2, bright=0.46, decay=1.9, seed=300 + i), b * beat, g)

    # 钟
    tr.add(bell(note("D3"), 7.0, decay=0.45, seed=6), 0.0, 0.18)
    tr.add(bell(note("F3"), 7.0, decay=0.42, seed=7), 16 * beat, 0.14)

    out = tr.done(dur)
    out = reverb(out, 2.8, 0.38, seed=8)
    return out


def make_layer3() -> np.ndarray:
    """第三层 · 妖窟：小二度冲突、急促、心跳脉动。84 BPM，8 小节 ≈ 22.8s。"""
    bpm = 84.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    tr = Track(dur + 3)

    # 铺底：D2 + Eb2（小二度，不安）
    tr.add(drone([note("D2"), note("D#2")], dur + 2.0, amp=0.22), 0.0)
    tr.add(wind(dur + 2.0, seed=31, cutoff=26) * 0.12, 0.0)

    # 心跳：每两拍一次，后半段加快
    for b in range(bars * 4):
        if b < 16 and b % 4 != 0:
            continue
        if b >= 16 and b % 2 != 0:
            continue
        tr.add(drum(f0=74, f1=38, seed=400 + b), b * beat, 0.26)

    # 急促拨弦：十六分音符碎片
    rng = np.random.default_rng(77)
    scale = ["D4", "D#4", "F4", "G4", "A4", "C5", "D5"]
    for b in range(bars * 4):
        for k in range(2):
            if rng.random() < 0.45:
                n = scale[int(rng.integers(0, len(scale)))]
                at = b * beat + k * beat * 0.5
                tr.add(pluck(note(n), 0.9, bright=0.68, decay=3.4, seed=500 + b * 2 + k),
                       at, 0.16 + 0.08 * rng.random())

    # 不谐和长音
    tr.add(bell(note("D#4"), 5.0, decay=0.8, seed=9), 8 * beat, 0.12)
    tr.add(bell(note("D4"), 5.0, decay=0.8, seed=10), 8.2 * beat, 0.10)

    out = tr.done(dur)
    out = reverb(out, 2.0, 0.30, seed=12)
    return out


def gen_bgm() -> None:
    print("== BGM ==")
    os.makedirs(BGM_DIR, exist_ok=True)
    jobs = [("layer1", make_layer1, 2.2), ("layer2", make_layer2, 2.2),
            ("layer3", make_layer3, 1.8)]
    for name, fn, tail in jobs:
        raw = fn()
        raw = loop_wrap(raw, tail)
        mono = soft_limit(raw, 0.86)
        data = stereo(mono, 0.10)
        stats(name, data)
        wav = os.path.join(BGM_DIR, f"{name}.wav")
        write_wav(wav, data)
        ogg = os.path.join(BGM_DIR, f"{name}.ogg")
        if to_ogg(wav, ogg):
            os.remove(wav)
            print(f"    → {os.path.relpath(ogg, ROOT)}  "
                  f"({os.path.getsize(ogg) / 1024:.0f} KB)")


# ---------------------------------------------------------------- SFX

def add_at(base: np.ndarray, sig: np.ndarray, at: float, gain: float = 1.0) -> np.ndarray:
    """把 sig 叠加到 base 的 at 秒处，自动裁到边界。"""
    i = int(at * SR)
    end = min(i + len(sig), len(base))
    if end > i:
        base[i:end] += sig[: end - i] * gain
    return base


def sfx_card_play() -> np.ndarray:
    out = pluck(note("A4"), 0.45, bright=0.6, decay=6.0, seed=1) * 0.7
    add_at(out, pluck(note("E5"), 0.3, bright=0.5, decay=8.0, seed=2), 0.02, 0.3)
    return out


def sfx_card_flip() -> np.ndarray:
    """翻面：噪声扫频 + 高频闪。"""
    t = t_axis(0.24)
    rng = np.random.default_rng(3)
    n = rng.normal(0, 1, len(t))
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(2200, 700, len(t))) / SR)
    out = n * 0.25 * np.exp(-16 * t) + sweep * 0.12 * np.exp(-9 * t)
    a = pluck(note("D6"), 0.16, bright=0.8, decay=14.0, seed=4) * 0.35
    out[: len(a)] += a
    return out


def sfx_hit() -> np.ndarray:
    t = t_axis(0.28)
    rng = np.random.default_rng(5)
    body = np.sin(2 * np.pi * np.cumsum(np.linspace(210, 70, len(t))) / SR) * np.exp(-17 * t)
    noise = rng.normal(0, 1, len(t))
    noise = np.convolve(noise, np.ones(4) / 4, "same") * np.exp(-26 * t)
    return body * 0.7 + noise * 0.5


def sfx_hit_heavy() -> np.ndarray:
    t = t_axis(0.5)
    rng = np.random.default_rng(6)
    body = np.sin(2 * np.pi * np.cumsum(np.linspace(150, 42, len(t))) / SR) * np.exp(-9 * t)
    noise = rng.normal(0, 1, len(t))
    noise = np.convolve(noise, np.ones(6) / 6, "same") * np.exp(-14 * t)
    return soft_limit(body * 0.85 + noise * 0.45, 0.95)


def sfx_hurt() -> np.ndarray:
    """玩家受伤：闷响 + 低频下坠。"""
    t = t_axis(0.45)
    down = np.sin(2 * np.pi * np.cumsum(np.linspace(320, 90, len(t))) / SR) * np.exp(-7 * t)
    thud = np.sin(2 * np.pi * 58 * t) * np.exp(-11 * t)
    return soft_limit(down * 0.45 + thud * 0.6, 0.92)


def sfx_block() -> np.ndarray:
    """格挡：金属短鸣。"""
    a = bell(note("A5"), 0.6, decay=6.0, seed=7) * 0.45
    b = bell(note("E6"), 0.5, decay=8.0, seed=8) * 0.22
    n = min(len(a), len(b))
    return a[:n] + b[:n]


def sfx_poison() -> np.ndarray:
    """上毒：气泡。"""
    t = t_axis(0.4)
    out = np.zeros_like(t)
    for i, (f, at) in enumerate([(420, 0.0), (520, 0.08), (350, 0.17), (460, 0.25)]):
        s = np.sin(2 * np.pi * f * t[at and int(at * SR) or 0:])
        seg = np.zeros_like(t)
        idx = int(at * SR)
        seg[idx:idx + len(s)] = s[: len(t) - idx] * np.exp(-30 * np.arange(len(s[: len(t) - idx])) / SR)
        out += seg * (0.5 - i * 0.06)
    return out * 0.6


def sfx_bind() -> np.ndarray:
    """缠绕：丝绸摩擦。"""
    t = t_axis(0.5)
    rng = np.random.default_rng(9)
    n = rng.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(12) / 12, "same")
    # 带通感：减去更长平滑
    n2 = np.convolve(n, np.ones(60) / 60, "same")
    band = n - n2
    env = np.exp(-5 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t))
    return band * env * 1.6


def sfx_draw() -> np.ndarray:
    """抽牌：纸片。"""
    t = t_axis(0.22)
    rng = np.random.default_rng(10)
    n = rng.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(5) / 5, "same")
    n2 = np.convolve(n, np.ones(40) / 40, "same")
    return (n - n2) * np.exp(-13 * t) * 1.4


def sfx_discard() -> np.ndarray:
    t = t_axis(0.26)
    rng = np.random.default_rng(11)
    n = rng.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(7) / 7, "same")
    n2 = np.convolve(n, np.ones(50) / 50, "same")
    env = np.exp(-9 * t) * np.linspace(1, 0.2, len(t))
    return (n - n2) * env * 1.2


def sfx_enemy_die() -> np.ndarray:
    """敌人消散：下坠 + 风散。"""
    t = t_axis(0.9)
    rng = np.random.default_rng(12)
    fall = np.sin(2 * np.pi * np.cumsum(np.linspace(600, 120, len(t))) / SR) * np.exp(-3.4 * t)
    n = rng.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(18) / 18, "same") * np.exp(-4.5 * t)
    return soft_limit(fall * 0.4 + n * 0.9, 0.9)


def sfx_victory() -> np.ndarray:
    """胜利：三音上行钟。"""
    out = np.zeros(int(1.8 * SR))
    for i, (n, at) in enumerate([("D4", 0.0), ("F4", 0.16), ("A4", 0.32), ("D5", 0.52)]):
        s = bell(note(n), 1.6, decay=1.6, seed=20 + i) * (0.5 - i * 0.05)
        idx = int(at * SR)
        end = min(idx + len(s), len(out))
        out[idx:end] += s[: end - idx]
    return out


def sfx_defeat() -> np.ndarray:
    """失败：低频下行长音。"""
    t = t_axis(2.4)
    f = np.linspace(160, 62, len(t))
    out = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-1.5 * t)
    out += np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR) * np.exp(-2.2 * t) * 0.4
    rng = np.random.default_rng(13)
    n = rng.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(30) / 30, "same") * np.exp(-2.0 * t)
    return soft_limit(out * 0.55 + n * 0.5, 0.9)


def sfx_coin() -> np.ndarray:
    """金币：两声金属叮。"""
    out = np.zeros(int(0.4 * SR))
    for i, (n, at) in enumerate([("A6", 0.0), ("E7", 0.07)]):
        s = bell(note(n), 0.3, decay=16.0, seed=30 + i) * 0.35
        idx = int(at * SR)
        end = min(idx + len(s), len(out))
        out[idx:end] += s[: end - idx]
    return out


def sfx_relic() -> np.ndarray:
    """获得旧物：钟 + 泛音。"""
    out = np.zeros(int(1.4 * SR))
    for i, (n, at, g) in enumerate([("D4", 0.0, 0.45), ("A4", 0.10, 0.3), ("D5", 0.22, 0.22)]):
        s = bell(note(n), 1.2, decay=2.6, seed=40 + i) * g
        idx = int(at * SR)
        end = min(idx + len(s), len(out))
        out[idx:end] += s[: end - idx]
    return out


def sfx_click() -> np.ndarray:
    """UI 点击：极短木鱼。"""
    return woodblock(0.09, 780.0, seed=50) * 0.55


def sfx_turn() -> np.ndarray:
    """回合开始：轻鼓。"""
    return drum(0.42, 110.0, 52.0, seed=60) * 0.75


def sfx_low_hp() -> np.ndarray:
    """低血心跳：两下闷响。"""
    out = np.zeros(int(0.7 * SR))
    for at, g in [(0.0, 0.6), (0.22, 0.4)]:
        s = drum(0.3, 68.0, 38.0, seed=70) * g
        idx = int(at * SR)
        end = min(idx + len(s), len(out))
        out[idx:end] += s[: end - idx]
    return out


SFX = {
    "card_play": sfx_card_play,
    "card_flip": sfx_card_flip,
    "hit": sfx_hit,
    "hit_heavy": sfx_hit_heavy,
    "hurt": sfx_hurt,
    "block": sfx_block,
    "poison": sfx_poison,
    "bind": sfx_bind,
    "draw": sfx_draw,
    "discard": sfx_discard,
    "enemy_die": sfx_enemy_die,
    "victory": sfx_victory,
    "defeat": sfx_defeat,
    "coin": sfx_coin,
    "relic": sfx_relic,
    "click": sfx_click,
    "turn": sfx_turn,
    "low_hp": sfx_low_hp,
}


def gen_sfx() -> None:
    print("== SFX ==")
    os.makedirs(SFX_DIR, exist_ok=True)
    for name, fn in SFX.items():
        x = fn()
        x = soft_limit(x, 0.92)
        # 统一去掉首尾静音，避免触发延迟
        idx = np.where(np.abs(x) > 0.004)[0]
        if len(idx):
            x = x[max(0, idx[0] - 32): min(len(x), idx[-1] + 200)]
        stats(name, x)
        path = os.path.join(SFX_DIR, f"{name}.wav")
        write_wav(path, x)
        print(f"    → {os.path.relpath(path, ROOT)}  ({os.path.getsize(path) / 1024:.0f} KB)")


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    if mode in ("bgm", "all"):
        gen_bgm()
    if mode in ("sfx", "all"):
        gen_sfx()
    print("\n完成。")


if __name__ == "__main__":
    main()

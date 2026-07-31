import numpy as np
from scipy.io.wavfile import write

sample_rate = 48000
duration = 8.0
t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)

# Langsame exponentielle Ladekurve
charge = 1.0 - np.exp(-t / 8.8)

# Feiner Ton, der langsam über die Hörgrenze steigt
f_start = 1200
f_end = 24000
frequency = f_start + (f_end - f_start) * charge

# Phase sauber integrieren
phase = 2 * np.pi * np.cumsum(frequency) / sample_rate

# Reiner Sinus
signal = np.sin(phase)

# Extrem weiches Einschleichen statt Attack
fade_in = 1.0 - np.exp(-t / 0.4)

# Der Ton wird mit zunehmender Frequenz leiser
frequency_fade = np.ones_like(t)
mask = frequency > 9000
frequency_fade[mask] = np.clip(
    1.0 - (frequency[mask] - 9000) / 13000,
    0.0,
    1.0
)

# Fade etwas glätten
frequency_fade = frequency_fade ** 1.4

signal *= fade_in * frequency_fade

# Kein hartes Normalisieren nötig
signal *= 0.45

signal = np.clip(signal, -1.0, 1.0)
signal = np.int16(signal * 32767)

write("capacitor_slow_fine.wav", sample_rate, signal)

print("capacitor_slow_fine.wav erzeugt")
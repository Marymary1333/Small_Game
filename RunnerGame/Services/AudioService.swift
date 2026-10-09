import AVFoundation
import os

enum SoundEffect: Equatable {
    case coin
    case lifeLost
}

enum AudioServiceError: Error, Equatable {
    case noOutputDevice
}

protocol AudioService: AnyObject {
    /// Starts the audio engine. Throws if audio is unavailable.
    func start() throws
    func play(_ effect: SoundEffect)
    /// Starts or resumes the music loop.
    func playMusic()
    /// Pauses the music loop, keeping its position.
    func pauseMusic()
    /// Stops the music loop and rewinds it.
    func stopMusic()
    func setMusicVolume(_ volume: Double)
    func setEffectsVolume(_ volume: Double)
}

/// Synthesizes all sounds at runtime: a coin chime, a life-lost buzz with crunch, and a calm ambient pad loop.
final class ToneSynthAudioService: AudioService {
    private struct Voice {
        let effect: SoundEffect
        var time: Double = 0
    }

    private struct State {
        var voices: [Voice] = []
        var musicPlaying = false
        var musicTime: Double = 0
        var musicVolume: Double = 0
        var effectsVolume: Double = 0
        var noiseSeed: UInt32 = 22_222
    }

    private let engine = AVAudioEngine()
    private let state = OSAllocatedUnfairLock(initialState: State())
    private var sourceNode: AVAudioSourceNode?

    func start() throws {
        let outputRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard outputRate > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: outputRate, channels: 1) else {
            throw AudioServiceError.noOutputDevice
        }
        let step = 1 / outputRate
        let node = AVAudioSourceNode(format: format) { [state] _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            state.withLock { s in
                for frame in 0..<Int(frameCount) {
                    let sample = Float(ToneSynthAudioService.renderSample(&s, step: step))
                    for buffer in buffers {
                        buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                    }
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try engine.start()
        sourceNode = node
    }

    func play(_ effect: SoundEffect) {
        state.withLock { $0.voices.append(Voice(effect: effect)) }
    }

    func playMusic() { state.withLock { $0.musicPlaying = true } }

    func pauseMusic() { state.withLock { $0.musicPlaying = false } }

    func stopMusic() {
        state.withLock {
            $0.musicPlaying = false
            $0.musicTime = 0
        }
    }

    func setMusicVolume(_ volume: Double) { state.withLock { $0.musicVolume = volume } }

    func setEffectsVolume(_ volume: Double) { state.withLock { $0.effectsVolume = volume } }

    // MARK: Synthesis (audio thread, inside the lock)

    private static let twoPi = 2 * Double.pi

    private static func renderSample(_ s: inout State, step: Double) -> Double {
        var effects = 0.0
        var index = 0
        while index < s.voices.count {
            let voice = s.voices[index]
            let (value, finished) = effectSample(voice, noise: nextNoise(&s.noiseSeed))
            effects += value
            if finished {
                s.voices.remove(at: index)
            } else {
                s.voices[index].time += step
                index += 1
            }
        }

        var music = 0.0
        if s.musicPlaying {
            music = musicSample(s.musicTime)
            s.musicTime += step
            if s.musicTime >= musicLoopLength { s.musicTime -= musicLoopLength }
        }

        let mixed = effects * s.effectsVolume + music * s.musicVolume
        return max(-1, min(1, mixed))
    }

    private static func effectSample(_ voice: Voice, noise: Double) -> (Double, Bool) {
        let t = voice.time
        switch voice.effect {
        case .coin:
            let duration = 0.3
            guard t < duration else { return (0, true) }
            let frequency = t < 0.07 ? 1318.5 : 1760.0          // E6 then A6
            let envelope = exp(-t * 12) * min(1, t * 400)
            return (0.35 * envelope * sin(twoPi * frequency * t), false)
        case .lifeLost:
            let duration = 0.45
            guard t < duration else { return (0, true) }
            let buzzPhase = (t * 110).truncatingRemainder(dividingBy: 1)
            let buzz = (buzzPhase < 0.5 ? 1.0 : -1.0) * exp(-t * 6) * 0.25
            let crunch = t < 0.12 ? noise * exp(-t * 30) * 0.35 : 0
            return (buzz + crunch, false)
        }
    }

    // Calm ambient pad: four slow chords (Am, F, C, G), 4 s each, soft attack and release.
    private static let musicLoopLength = 16.0
    private static let chords: [[Double]] = [
        [220.00, 261.63, 329.63],   // A minor
        [174.61, 220.00, 261.63],   // F major
        [130.81, 164.81, 196.00],   // C major
        [196.00, 246.94, 293.66],   // G major
    ]

    private static func musicSample(_ t: Double) -> Double {
        let chordLength = musicLoopLength / Double(chords.count)
        let chordIndex = Int(t / chordLength) % chords.count
        let local = t - Double(chordIndex) * chordLength
        let fade = min(1, local / 1.2) * min(1, (chordLength - local) / 1.2)
        let tremolo = 0.85 + 0.15 * sin(twoPi * 0.25 * t)
        var value = 0.0
        for frequency in chords[chordIndex] {
            value += sin(twoPi * frequency * t) + 0.3 * sin(twoPi * frequency * 2 * t)
        }
        return value * 0.07 * fade * tremolo
    }

    private static func nextNoise(_ seed: inout UInt32) -> Double {
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return Double(seed) / Double(UInt32.max) * 2 - 1
    }
}

import { useCallback, useEffect, useRef, useState } from 'react'

export interface SpeakOptions {
  lang: string
  voiceURI?: string
  rate: number
  pitch: number
}

export function normaliseLang(lang: string): string {
  return lang.replace(/_/g, '-')
}

export function useSpeech() {
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([])
  const [isSpeaking, setIsSpeaking] = useState(false)
  const current = useRef<SpeechSynthesisUtterance | null>(null)
  const watchdog = useRef<number | null>(null)
  const supported = typeof window !== 'undefined' && 'speechSynthesis' in window

  useEffect(() => {
    if (!supported) return
    const load = () => {
      const all = window.speechSynthesis.getVoices()
      setVoices(all.filter((voice) => normaliseLang(voice.lang).toLowerCase().startsWith('en')))
    }
    load()
    // Android Chrome often returns an empty list on the first call.
    const retry = window.setTimeout(load, 300)
    window.speechSynthesis.addEventListener('voiceschanged', load)
    return () => {
      window.clearTimeout(retry)
      window.speechSynthesis.removeEventListener('voiceschanged', load)
    }
  }, [supported])

  const clearWatchdog = () => {
    if (watchdog.current) window.clearTimeout(watchdog.current)
    watchdog.current = null
  }

  const stop = useCallback(() => {
    if (supported) window.speechSynthesis.cancel()
    clearWatchdog()
    current.current = null
    setIsSpeaking(false)
  }, [supported])

  const speak = useCallback((text: string, options: SpeakOptions, onEnd?: () => void) => {
    if (!supported) {
      onEnd?.()
      return
    }
    const synth = window.speechSynthesis
    // Cancelling an idle Android engine can swallow the next utterance.
    if (synth.speaking || synth.pending) synth.cancel()
    synth.resume()

    const utterance = new SpeechSynthesisUtterance(text)
    const wanted = normaliseLang(options.lang).toLowerCase()
    const exact = voices.find((voice) => voice.voiceURI === options.voiceURI)
      ?? voices.find((voice) => voice.localService && normaliseLang(voice.lang).toLowerCase() === wanted)
      ?? voices.find((voice) => normaliseLang(voice.lang).toLowerCase() === wanted)
      ?? voices.find((voice) => voice.localService && normaliseLang(voice.lang).toLowerCase().startsWith(wanted.split('-')[0]))
      ?? voices.find((voice) => voice.localService)
      ?? voices[0]

    if (exact) utterance.voice = exact
    // Android voices can expose en_US; SpeechSynthesisUtterance expects en-US.
    utterance.lang = normaliseLang(exact?.lang ?? options.lang)
    utterance.rate = options.rate
    utterance.pitch = options.pitch
    utterance.volume = 1

    let finished = false
    let retry = 0
    const finish = () => {
      if (finished) return
      finished = true
      clearWatchdog()
      window.clearTimeout(retry)
      if (current.current !== utterance) return
      current.current = null
      setIsSpeaking(false)
      onEnd?.()
    }

    utterance.onend = finish
    utterance.onerror = finish

    current.current = utterance
    setIsSpeaking(true)

    // Speak immediately so the first tap keeps its user activation. Some
    // Android engines ignore the first call after cancel(); retry once if the
    // engine has not started.
    let started = false
    let retried = false
    utterance.onstart = () => { started = true }
    synth.speak(utterance)
    synth.resume()
    retry = window.setTimeout(() => {
      if (started || retried || current.current !== utterance || synth.speaking || synth.pending) return
      retried = true
      if (synth.speaking || synth.pending) synth.cancel()
      synth.speak(utterance)
      synth.resume()
    }, 1200)

    // Some Android builds never fire onend/onerror. Keep autoplay moving with
    // a deliberately generous estimate; onend cancels this when it works.
    const estimate = Math.min(30_000, 2_000 + (text.length * 250) / Math.max(options.rate, 0.3))
    clearWatchdog()
    watchdog.current = window.setTimeout(finish, estimate)
  }, [supported, voices])

  return { voices, isSpeaking, supported, speak, stop }
}

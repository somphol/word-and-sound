import { useCallback, useEffect, useRef, useState } from 'react'

export interface SpeakOptions {
  lang: string
  voiceURI?: string
  rate: number
  pitch: number
}

export function useSpeech() {
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([])
  const [isSpeaking, setIsSpeaking] = useState(false)
  const current = useRef<SpeechSynthesisUtterance | null>(null)

  useEffect(() => {
    if (!('speechSynthesis' in window)) return
    const load = () => {
      setVoices(window.speechSynthesis.getVoices().filter((voice) => voice.lang.startsWith('en')))
    }
    load()
    window.speechSynthesis.addEventListener('voiceschanged', load)
    return () => window.speechSynthesis.removeEventListener('voiceschanged', load)
  }, [])

  const stop = useCallback(() => {
    if ('speechSynthesis' in window) window.speechSynthesis.cancel()
    current.current = null
    setIsSpeaking(false)
  }, [])

  const speak = useCallback((text: string, options: SpeakOptions, onEnd?: () => void) => {
    if (!('speechSynthesis' in window)) return
    window.speechSynthesis.cancel()
    const utterance = new SpeechSynthesisUtterance(text)
    const selected = voices.find((voice) => voice.voiceURI === options.voiceURI)
      ?? voices.find((voice) => voice.lang === options.lang)
      ?? voices[0]
    if (selected) utterance.voice = selected
    utterance.lang = selected?.lang ?? options.lang
    utterance.rate = options.rate
    utterance.pitch = options.pitch
    utterance.onend = () => {
      if (current.current !== utterance) return
      current.current = null
      setIsSpeaking(false)
      onEnd?.()
    }
    utterance.onerror = () => {
      if (current.current !== utterance) return
      current.current = null
      setIsSpeaking(false)
    }
    current.current = utterance
    setIsSpeaking(true)
    window.speechSynthesis.speak(utterance)
  }, [voices])

  return { voices, isSpeaking, speak, stop }
}

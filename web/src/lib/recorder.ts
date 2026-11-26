import { useCallback, useEffect, useRef, useState } from 'react'

export function useRecorder() {
  const [recording, setRecording] = useState(false)
  const [url, setUrl] = useState<string | null>(null)
  const [elapsed, setElapsed] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const recorder = useRef<MediaRecorder | null>(null)
  const chunks = useRef<Blob[]>([])
  const stream = useRef<MediaStream | null>(null)
  const started = useRef(0)
  const timer = useRef<number | null>(null)

  const reset = useCallback(() => {
    if (timer.current) window.clearInterval(timer.current)
    timer.current = null
    recorder.current?.state === 'recording' && recorder.current.stop()
    stream.current?.getTracks().forEach((track) => track.stop())
    stream.current = null
    recorder.current = null
    if (url) URL.revokeObjectURL(url)
    setUrl(null)
    setRecording(false)
    setElapsed(0)
  }, [url])

  useEffect(() => reset, []) // eslint-disable-line react-hooks/exhaustive-deps

  const start = useCallback(async () => {
    setError(null)
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      setError('Recording is not supported in this browser.')
      return
    }
    try {
      const media = await navigator.mediaDevices.getUserMedia({ audio: true })
      stream.current = media
      chunks.current = []
      const next = new MediaRecorder(media)
      next.ondataavailable = (event) => event.data.size && chunks.current.push(event.data)
      next.onstop = () => {
        const blob = new Blob(chunks.current, { type: next.mimeType || 'audio/webm' })
        setUrl(URL.createObjectURL(blob))
        stream.current?.getTracks().forEach((track) => track.stop())
        stream.current = null
      }
      recorder.current = next
      started.current = Date.now()
      next.start()
      setRecording(true)
      setElapsed(0)
      timer.current = window.setInterval(() => {
        setElapsed((Date.now() - started.current) / 1000)
      }, 100)
    } catch {
      setError('Microphone access was denied. Allow it in the browser’s site settings.')
    }
  }, [])

  const stop = useCallback(() => {
    if (recorder.current?.state === 'recording') recorder.current.stop()
    if (timer.current) window.clearInterval(timer.current)
    timer.current = null
    setRecording(false)
  }, [])

  const play = useCallback(() => {
    if (!url) return
    const audio = new Audio(url)
    void audio.play()
  }, [url])

  return { recording, url, elapsed, error, start, stop, play, reset }
}

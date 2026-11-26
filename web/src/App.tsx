import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type {
  AppData, ImportedList, ListSource, SearchFilter, SoundTile, WordProgress,
} from './lib/types'
import { allTiles, categoryForTile, componentsFor, loadData, wordsForTile } from './lib/data'
import { useSpeech } from './lib/speech'
import {
  dueCount, loadImported, loadPositions, loadProgress, loadSettings, nextDue, nextStep,
  parseWordList, reviewWords, saveImported, savePositions, saveProgress, saveSettings,
  type Settings,
} from './lib/progress'
import { buildWordIndex, searchResults } from './lib/search'
import { ipaParts, rowIPA, targetDescription } from './lib/ipa'
import { Header } from './components/Header'
import { BottomNav, type Screen } from './components/BottomNav'
import { CategoryTabs } from './components/CategoryTabs'
import { SoundPanel } from './components/SoundPanel'
import { WordPanel } from './components/WordPanel'
import { FocusCard } from './components/FocusCard'
import { Icon } from './components/Icon'
import { MixedPanel } from './components/MixedPanel'
import { SearchPalette } from './components/SearchPalette'
import { PracticeModal } from './components/PracticeModal'
import { CoachModal } from './components/CoachModal'
import { SettingsModal } from './components/SettingsModal'
import { CreditsModal } from './components/CreditsModal'
import { RecordDialog } from './components/RecordDialog'
import type { MixedList } from './lib/types'

type Modal = 'search' | 'practice' | 'coach' | 'settings' | 'credits' | 'record' | null

const REVIEW_LIST: Omit<MixedList, 'source'> = {
  id: 'review', title: 'Review', author: 'This Mac', license: 'Local', url: '',
}

export default function App() {
  const [settings, setSettings] = useState<Settings>(() => loadSettings())
  const [source, setSource] = useState<ListSource>(settings.listSource)
  const [category, setCategory] = useState(settings.category)
  const [tileId, setTileId] = useState(settings.tile)
  const [mixedId, setMixedId] = useState(settings.mixed)
  const [data, setData] = useState<AppData | null>(null)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [progress, setProgress] = useState<Record<string, WordProgress>>(() => loadProgress())
  const [positions, setPositions] = useState<Record<string, string>>(() => loadPositions())
  const [imported, setImported] = useState<ImportedList[]>(() => loadImported())
  const [index, setIndex] = useState(0)
  const [searchText, setSearchText] = useState('')
  const [autoplay, setAutoplay] = useState(false)
  const [modal, setModal] = useState<Modal>(null)
  const [screen, setScreen] = useState<Screen>('practice')
  const [isPhone, setIsPhone] = useState(() => window.matchMedia('(max-width: 700px)').matches)
  const [desktopMode] = useState(() => window.screen.width <= 600 && window.innerWidth > 700)
  const [bannerDismissed, setBannerDismissed] = useState(() => sessionStorage.getItem('word-and-sound:desktop-hint') === '1')
  const [libraryOpen, setLibraryOpen] = useState(false)
  const [libraryTab, setLibraryTab] = useState<'sounds' | 'lists'>('sounds')
  const [wordsOpen, setWordsOpen] = useState(false)
  const [coachTile, setCoachTile] = useState<SoundTile | null>(null)
  const [pendingWord, setPendingWord] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)
  const fileInput = useRef<HTMLInputElement>(null)
  const speech = useSpeech()

  const autoplayRef = useRef(false)
  const repeatRef = useRef(settings.repeatCount)
  const wordsRef = useRef<string[]>([])
  const indexRef = useRef(0)
  const listKeyRef = useRef('')
  const settingsRef = useRef(settings)
  const timerRef = useRef<number | null>(null)
  const speakAtRef = useRef<(i: number) => void>(() => {})
  const handleEndRef = useRef<() => void>(() => {})
  const commandsRef = useRef({ play: () => {}, next: () => {}, previous: () => {}, replay: () => {} })

  useEffect(() => {
    const media = window.matchMedia('(max-width: 700px)')
    const onChange = () => setIsPhone(media.matches)
    media.addEventListener('change', onChange)
    return () => media.removeEventListener('change', onChange)
  }, [])

  useEffect(() => {
    if (!isPhone) setScreen('practice')
  }, [isPhone])

  useEffect(() => {
    const onPop = (event: PopStateEvent) => {
      const next = (event.state as { screen?: Screen } | null)?.screen
      setScreen(next ?? 'practice')
    }
    window.addEventListener('popstate', onPop)
    return () => window.removeEventListener('popstate', onPop)
  }, [])

  useEffect(() => {
    if (!isPhone || screen === 'practice') return
    window.history.pushState({ screen }, '')
  }, [screen, isPhone])

  useEffect(() => {
    const onEscape = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return
      setLibraryOpen(false)
      setWordsOpen(false)
      setModal(null)
    }
    window.addEventListener('keydown', onEscape)
    return () => window.removeEventListener('keydown', onEscape)
  }, [])

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        setModal('search')
        return
      }
      const target = event.target as HTMLElement | null
      if (target && (target.isContentEditable || ['INPUT', 'SELECT', 'TEXTAREA'].includes(target.tagName))) return
      if (document.querySelector('.overlay')) return
      if (event.key === ' ') {
        event.preventDefault()
        commandsRef.current.play()
        return
      }
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'r') {
        event.preventDefault()
        commandsRef.current.replay()
        return
      }
      if (event.metaKey || event.ctrlKey) {
        if (event.key === 'ArrowRight') {
          event.preventDefault()
          commandsRef.current.next()
        } else if (event.key === 'ArrowLeft') {
          event.preventDefault()
          commandsRef.current.previous()
        }
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  useEffect(() => {
    loadData().then(setData).catch((error: unknown) => {
      setLoadError(error instanceof Error ? error.message : 'Could not load the data bundle.')
    })
  }, [])

  const tiles = useMemo(() => data ? allTiles(data.library) : [], [data])
  const activeTile = tiles.find((tile) => tile.id === tileId) ?? tiles[0] ?? null
  const review = useMemo(() => reviewWords(progress), [progress])

  const mixedLists = useMemo<MixedList[]>(() => {
    if (!data) return []
    const lists: MixedList[] = [
      ...data.library.mixed,
      ...imported.map((list) => ({
        id: list.id, title: list.title, source: 'Imported', author: 'You',
        license: 'Your own content', url: '',
      })),
    ]
    if (review.length) {
      lists.unshift({
        ...REVIEW_LIST,
        source: `${review.length} words · ${dueCount(progress)} due · favorites and trouble`,
      })
    }
    return lists
  }, [data, imported, review, progress])

  const activeMixed = mixedLists.find((list) => list.id === mixedId) ?? null
  const words = useMemo(() => {
    if (!data) return []
    if (category === 'mixed') {
      if (!activeMixed) return []
      if (activeMixed.id === 'review') return review
      return imported.find((list) => list.id === activeMixed.id)?.words
        ?? data.library.lists[activeMixed.id] ?? []
    }
    return activeTile ? wordsForTile(data, activeTile, source) : []
  }, [data, category, activeTile, source, activeMixed, imported, review])

  const listKey = category === 'mixed' ? activeMixed?.id ?? '' : activeTile?.id ?? ''
  const listTitle = category === 'mixed'
    ? activeMixed?.title ?? 'Word list'
    : activeTile ? `${data?.library.categories.find((group) => group.tiles.includes(activeTile))?.title ?? 'Sound'} · ${activeTile.label}` : 'Word list'
  const currentWord = words[index] ?? null
  const currentTargets = activeTile?.targets ?? []
  const currentKind = activeTile?.kind ?? 'onset'
  const parts = currentWord && data ? ipaParts(data.us, data.uk, currentWord, settings.ipaMode) : []
  const practised = words.reduce((total, word) => total + ((progress[word.toLowerCase()]?.listens ?? 0) > 0 ? 1 : 0), 0)
  const wordIndex = useMemo(() => data ? buildWordIndex(data, source, imported) : new Map(), [data, source, imported])

  wordsRef.current = words
  indexRef.current = index
  listKeyRef.current = listKey
  settingsRef.current = settings
  autoplayRef.current = autoplay

  const updateProgress = useCallback((word: string, mutate: (item: WordProgress) => WordProgress) => {
    setProgress((previous) => {
      const key = word.toLowerCase()
      const base: WordProgress = previous[key] ?? {
        word, listens: 0, correct: 0, wrong: 0, step: 0, due: null,
        favorite: false, trouble: false, lastSeen: null,
      }
      const next = { ...previous, [key]: mutate(base) }
      saveProgress(next)
      return next
    })
  }, [])

  const recordListen = useCallback((word: string) => {
    updateProgress(word, (item) => ({
      ...item, listens: item.listens + 1, lastSeen: Date.now(),
    }))
  }, [updateProgress])

  const savePosition = useCallback((word: string) => {
    const key = listKeyRef.current
    if (!key) return
    setPositions((previous) => {
      const next = { ...previous, [key]: word }
      savePositions(next)
      return next
    })
  }, [])

  const speakWord = useCallback((word: string, slow = false) => {
    const current = settingsRef.current
    recordListen(word)
    savePosition(word)
    speech.speak(word, {
      lang: current.accent,
      voiceURI: current.voiceURI,
      rate: slow ? Math.min(current.rate, 0.6) : current.rate,
      pitch: current.pitch,
    }, () => handleEndRef.current())
  }, [recordListen, savePosition, speech])

  const speakAt = useCallback((targetIndex: number) => {
    const word = wordsRef.current[targetIndex]
    if (!word) return
    setIndex(targetIndex)
    indexRef.current = targetIndex
    speakWord(word)
  }, [speakWord])
  speakAtRef.current = speakAt

  const schedule = useCallback((targetIndex: number) => {
    if (timerRef.current) window.clearTimeout(timerRef.current)
    timerRef.current = window.setTimeout(() => {
      if (autoplayRef.current) speakAtRef.current(targetIndex)
    }, Math.max(1, settingsRef.current.delay) * 1000)
  }, [])

  handleEndRef.current = () => {
    if (!autoplayRef.current || wordsRef.current.length === 0) return
    if (repeatRef.current > 1) {
      repeatRef.current -= 1
      schedule(indexRef.current)
    } else {
      repeatRef.current = settingsRef.current.repeatCount
      const next = (indexRef.current + 1) % wordsRef.current.length
      setIndex(next)
      indexRef.current = next
      schedule(next)
    }
  }

  const stopPlayback = useCallback(() => {
    speech.stop()
    setAutoplay(false)
    autoplayRef.current = false
    if (timerRef.current) window.clearTimeout(timerRef.current)
    timerRef.current = null
  }, [speech])

  const toggleAutoplay = useCallback(() => {
    if (autoplayRef.current) {
      stopPlayback()
    } else {
      if (!wordsRef.current.length) return
      autoplayRef.current = true
      setAutoplay(true)
      repeatRef.current = settingsRef.current.repeatCount
      speakAtRef.current(indexRef.current)
    }
  }, [stopPlayback])

  const selectCategory = (next: string) => {
    stopPlayback()
    setCategory(next)
    if (next === 'mixed') {
      setMixedId(mixedLists[0]?.id ?? '')
      setTileId('')
    } else {
      const group = data?.library.categories.find((item) => item.id === next)
      setTileId(group?.tiles[0]?.id ?? '')
      setMixedId('')
    }
  }

  const selectTile = (tile: SoundTile) => {
    stopPlayback()
    const group = data ? categoryForTile(data.library, tile.id) : undefined
    if (group) setCategory(group.id)
    setTileId(tile.id)
    setMixedId('')
  }

  const selectMixed = (list: MixedList) => {
    stopPlayback()
    setCategory('mixed')
    setMixedId(list.id)
    setTileId('')
  }

  const selectWord = (next: number) => {
    if (!words[next]) return
    if (timerRef.current) window.clearTimeout(timerRef.current)
    setIndex(next)
    indexRef.current = next
    repeatRef.current = settings.repeatCount
    speakWord(words[next])
  }

  const nextWord = () => {
    if (!words.length) return
    const next = (index + 1) % words.length
    setIndex(next)
    indexRef.current = next
    repeatRef.current = settings.repeatCount
    speakWord(words[next])
  }

  const previousWord = () => {
    if (!words.length) return
    const next = (index - 1 + words.length) % words.length
    setIndex(next)
    indexRef.current = next
    repeatRef.current = settings.repeatCount
    speakWord(words[next])
  }

  commandsRef.current = {
    play: () => speakAtRef.current(indexRef.current),
    next: () => {
      if (!wordsRef.current.length) return
      const next = (indexRef.current + 1) % wordsRef.current.length
      speakAtRef.current(next)
    },
    previous: () => {
      if (!wordsRef.current.length) return
      const next = (indexRef.current - 1 + wordsRef.current.length) % wordsRef.current.length
      speakAtRef.current(next)
    },
    replay: () => {
      const word = wordsRef.current[indexRef.current]
      if (word) speakWord(word)
    },
  }

  const toggleFavorite = (word: string) => {
    updateProgress(word, (item) => ({ ...item, favorite: !item.favorite }))
  }

  const toggleTrouble = (word: string) => {
    updateProgress(word, (item) => ({ ...item, trouble: !item.trouble }))
  }

  const recordQuiz = (word: string, correct: boolean) => {
    updateProgress(word, (item) => correct
      ? { ...item, correct: item.correct + 1, step: nextStep(item.step, true), due: nextDue(nextStep(item.step, true)), lastSeen: Date.now() }
      : { ...item, wrong: item.wrong + 1, step: 0, due: Date.now(), lastSeen: Date.now() })
  }

  const reviewAnswer = (correct: boolean) => {
    if (!currentWord) return
    const word = currentWord
    recordQuiz(word, correct)
    if (category === 'mixed' && mixedId === 'review') {
      const nextProgress = { ...progress }
      const key = word.toLowerCase()
      const item = nextProgress[key]
      const updated = correct
        ? { ...item, step: nextStep(item.step, true), due: nextDue(nextStep(item.step, true)) }
        : { ...item, step: 0, due: Date.now() }
      nextProgress[key] = updated
      const nextReview = reviewWords(nextProgress)
      if (!nextReview.length) {
        stopPlayback()
        setMixedId('')
        return
      }
      const same = nextReview.findIndex((entry) => entry.toLowerCase() === word.toLowerCase())
      const nextIndex = same >= 0 ? (same + 1) % nextReview.length : Math.min(index, nextReview.length - 1)
      setIndex(nextIndex)
      indexRef.current = nextIndex
      speakWord(nextReview[nextIndex])
    } else {
      nextWord()
    }
  }

  useEffect(() => {
    if (!data) return
    if (category === 'mixed') {
      if (!mixedLists.some((list) => list.id === mixedId)) setMixedId(mixedLists[0]?.id ?? '')
      return
    }
    const group = data.library.categories.find((item) => item.id === category) ?? data.library.categories[0]
    if (group.id !== category) setCategory(group.id)
    if (!group.tiles.some((tile) => tile.id === tileId)) setTileId(group.tiles[0].id)
  }, [data, category, tileId, mixedId, mixedLists])

  useEffect(() => {
    if (!listKey) return
    const saved = positions[listKey]
    const found = saved ? words.findIndex((word) => word.toLowerCase() === saved.toLowerCase()) : -1
    setIndex(found >= 0 ? found : 0)
  }, [listKey, source, data]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (index >= words.length) setIndex(Math.max(0, words.length - 1))
  }, [index, words.length])

  useEffect(() => {
    saveSettings({ ...settings, category, tile: tileId, mixed: mixedId, listSource: source })
  }, [settings, category, tileId, mixedId, source])

  useEffect(() => {
    document.documentElement.style.fontSize = `${(16 * settings.textScale).toFixed(2)}px`
  }, [settings.textScale])

  useEffect(() => {
    document.documentElement.style.setProperty('--word-scale', String(settings.wordScale))
  }, [settings.wordScale])

  useEffect(() => {
    if (!pendingWord || !words.length) return
    const found = words.findIndex((word) => word.toLowerCase() === pendingWord.toLowerCase())
    if (found >= 0) {
      setPendingWord(null)
      setIndex(found)
      indexRef.current = found
      speakAtRef.current(found)
    }
  }, [pendingWord, words])

  const openSearchWord = (hit: { word: string; tileID: string | null; listID: string }) => {
    stopPlayback()
    setPendingWord(hit.word)
    if (hit.tileID) {
      const tile = tiles.find((item) => item.id === hit.tileID)
      if (tile) selectTile(tile)
    } else {
      const list = mixedLists.find((item) => item.id === hit.listID)
      if (list) selectMixed(list)
    }
    setModal(null)
  }

  const importFile = async (file: File) => {
    const text = await file.text()
    const parsed = parseWordList(text)
    if (!parsed.length) {
      setToast('No usable words found in that file.')
      return
    }
    const list: ImportedList = {
      id: `imported-${Date.now()}`,
      title: file.name.replace(/\.[^.]+$/, '') || 'Imported list',
      words: parsed,
      source: file.name,
    }
    const next = [...imported, list]
    setImported(next)
    saveImported(next)
    setCategory('mixed')
    setMixedId(list.id)
    setScreen('practice')
    setToast(`Imported ${parsed.length} words from ${file.name}.`)
  }

  const resetProgress = () => {
    setProgress({})
    saveProgress({})
    if (mixedId === 'review') setMixedId('')
    setToast('Practice history reset.')
  }

  const resetSettings = () => {
    const fresh: Settings = {
      ...settings, listSource: 'built', accent: 'en-US', voiceURI: '', repeatCount: 1,
      delay: 2, rate: 1, pitch: 1, ipaMode: 'both', textScale: 1, wordScale: 1,
    }
    setSettings(fresh)
    setSource('built')
  }

  const openCoach = (tile: SoundTile) => {
    setCoachTile(tile)
    setModal('coach')
  }

  const countForList = (list: MixedList) => list.id === 'review'
    ? review.length
    : imported.find((item) => item.id === list.id)?.words.length ?? data!.library.lists[list.id]?.length ?? 0

  const activeScreen: Screen = isPhone ? screen : 'practice'
  const coachComponents = coachTile && data ? componentsFor(coachTile.label, data.articulation) : []
  const coachSamples = coachTile && activeTile?.id === coachTile.id ? words.slice(0, 6) : []

  if (loadError) {
    return (
      <main className="loading">
        <h1>Word &amp; Sound</h1>
        <p>{loadError}</p>
        <p>Run the app from the `web/` directory or check `public/data/`.</p>
      </main>
    )
  }
  if (!data) {
    return <main className="loading"><h1>Word &amp; Sound</h1><p>Loading the data bundle…</p></main>
  }

  return (
    <div className="app">
      <Header
        category={category}
        source={source}
        onCategory={selectCategory}
        onSource={(next) => { stopPlayback(); setSource(next) }}
        onSearch={() => setModal('search')}
        onPractice={() => setModal('practice')}
        onImport={() => fileInput.current?.click()}
        onSettings={() => setModal('settings')}
        onCredits={() => setModal('credits')}
        version={__APP_VERSION__}
        reviewCount={review.length}
      />
      {activeScreen === 'practice' && (
      <main className="stage">
        <div className="context-row">
          <button
            type="button"
            className="context-pill"
            onClick={() => {
              if (isPhone) {
                setScreen('sounds')
                return
              }
              setLibraryTab(category === 'mixed' ? 'lists' : 'sounds')
              setLibraryOpen(true)
            }}
          >
            <Icon name={category === 'mixed' ? 'list' : 'grid'} size={15} />
            <strong>{category === 'mixed' ? activeMixed?.title ?? 'Lists' : activeTile ? `${activeTile.label} · ${activeTile.exampleWord}` : 'Sounds'}</strong>
            <Icon name="chevronRight" size={14} />
          </button>
          <button type="button" className="context-pill" onClick={() => isPhone ? setScreen('words') : setWordsOpen(true)}>
            <Icon name="list" size={15} />
            <strong>Words</strong>
            <span className="context-count">{words.length}</span>
          </button>
          {review.length > 0 && <span className="context-hint">{review.length} to review</span>}
          <span className="context-index">{words.length ? `${index + 1} / ${words.length}` : ''}</span>
        </div>

        <FocusCard
          word={currentWord}
          parts={parts}
          target={targetDescription(activeTile)}
          eyebrow={listTitle}
          listTitle={listTitle}
          targets={currentTargets}
          kind={currentKind}
          index={index}
          total={words.length}
          practised={practised}
          settings={settings}
          voices={speech.voices}
          autoplay={autoplay}
          isSpeaking={speech.isSpeaking}
          favorite={!!currentWord && !!progress[currentWord.toLowerCase()]?.favorite}
          trouble={!!currentWord && !!progress[currentWord.toLowerCase()]?.trouble}
          isReview={category === 'mixed' && mixedId === 'review'}
          onSettings={(next) => setSettings({ ...settings, ...next })}
          onPlay={() => { repeatRef.current = settings.repeatCount; speakAtRef.current(index) }}
          onStop={stopPlayback}
          onSlow={() => currentWord && speakWord(currentWord, true)}
          onPrevious={previousWord}
          onNext={nextWord}
          onToggleAutoplay={toggleAutoplay}
          onReplay={() => currentWord && speakWord(currentWord)}
          onFavorite={() => currentWord && toggleFavorite(currentWord)}
          onTrouble={() => currentWord && toggleTrouble(currentWord)}
          onCoach={() => activeTile && openCoach(activeTile)}
          onRecord={() => setModal('record')}
          onGotIt={() => reviewAnswer(true)}
          onAgain={() => reviewAnswer(false)}
        />

        <p className="stage-hint">Space play · ⌘R replay · ⌘←/→ move · ⌘K search</p>
      </main>
      )}

      {activeScreen === 'sounds' && (
        <main className="screen-page sounds-screen">
          <div className="screen-toolbar">
            <CategoryTabs category={category} onCategory={selectCategory} />
          </div>
          {category === 'mixed' ? (
            <MixedPanel
              lists={mixedLists}
              selectedId={mixedId}
              wordCount={countForList}
              onSelect={(list) => { selectMixed(list); setScreen('practice') }}
              onImport={() => fileInput.current?.click()}
            />
          ) : (
            <SoundPanel
              data={data}
              category={category}
              source={source}
              activeTile={activeTile}
              progress={progress}
              onSelect={(tile) => { selectTile(tile); setScreen('practice') }}
              onCoach={openCoach}
              onSourceChange={(next) => { stopPlayback(); setSource(next) }}
            />
          )}
        </main>
      )}

      {activeScreen === 'words' && (
        <main className="screen-page words-screen">
          <WordPanel
            data={data}
            title={listTitle}
            words={words}
            currentIndex={index}
            searchText={searchText}
            onSearchChange={setSearchText}
            practised={practised}
            progress={progress}
            targets={currentTargets}
            kind={currentKind}
            ipaMode={settings.ipaMode}
            onSelect={(next) => { selectWord(next); setScreen('practice') }}
            onFavorite={toggleFavorite}
            onTrouble={toggleTrouble}
            reviewCount={review.length}
            onReview={() => {
              const list = mixedLists.find((item) => item.id === 'review')
              if (list) {
                selectMixed(list)
                setScreen('practice')
              }
            }}
          />
        </main>
      )}

      {desktopMode && !bannerDismissed && (
        <div className="viewport-banner" role="status">
          <Icon name="info" size={20} />
          <p>Desktop site is on. For the phone layout, open your browser menu and turn off <b>Desktop site</b>.</p>
          <button
            type="button"
            className="icon-button"
            aria-label="Dismiss desktop-mode hint"
            onClick={() => {
              sessionStorage.setItem('word-and-sound:desktop-hint', '1')
              setBannerDismissed(true)
            }}
          ><Icon name="close" size={16} /></button>
        </div>
      )}

      {libraryOpen && (
        <div
          className="overlay sheet-overlay library"
          onMouseDown={(event) => event.target === event.currentTarget && setLibraryOpen(false)}
        >
          <section className="library-sheet" role="dialog" aria-modal="true" aria-label="Sounds and lists">
            <header className="sheet-head">
              <div className="sheet-tabs" role="tablist" aria-label="Library">
                <button type="button" role="tab" aria-selected={libraryTab === 'sounds'} className={libraryTab === 'sounds' ? 'active' : ''} onClick={() => setLibraryTab('sounds')}>Sounds</button>
                <button type="button" role="tab" aria-selected={libraryTab === 'lists'} className={libraryTab === 'lists' ? 'active' : ''} onClick={() => setLibraryTab('lists')}>Lists</button>
              </div>
              <span className="sheet-note">{libraryTab === 'sounds' ? `${tiles.length} sounds` : `${mixedLists.length} lists`}</span>
              <button type="button" className="icon-button" onClick={() => setLibraryOpen(false)} aria-label="Close library">
                <Icon name="close" />
              </button>
            </header>
            <div className="sheet-body">
              {libraryTab === 'sounds' ? (
                <SoundPanel
                  data={data}
                  category={category}
                  source={source}
                  activeTile={activeTile}
                  progress={progress}
                  onSelect={(tile) => { selectTile(tile); setLibraryOpen(false) }}
                  onCoach={(tile) => { setLibraryOpen(false); openCoach(tile) }}
                  onSourceChange={(next) => { stopPlayback(); setSource(next) }}
                />
              ) : (
                <MixedPanel
                  lists={mixedLists}
                  selectedId={mixedId}
                  wordCount={countForList}
                  onSelect={(list) => { selectMixed(list); setLibraryOpen(false) }}
                  onImport={() => { setLibraryOpen(false); fileInput.current?.click() }}
                />
              )}
            </div>
          </section>
        </div>
      )}

      {wordsOpen && (
        <div
          className="overlay sheet-overlay drawer"
          onMouseDown={(event) => event.target === event.currentTarget && setWordsOpen(false)}
        >
          <aside className="words-drawer" role="dialog" aria-modal="true" aria-label="Word list">
            <WordPanel
              data={data}
              title={listTitle}
              words={words}
              currentIndex={index}
              searchText={searchText}
              onSearchChange={setSearchText}
              practised={practised}
              progress={progress}
              targets={currentTargets}
              kind={currentKind}
              ipaMode={settings.ipaMode}
              onSelect={(next) => { setWordsOpen(false); selectWord(next) }}
              onFavorite={toggleFavorite}
              onTrouble={toggleTrouble}
              onClose={() => setWordsOpen(false)}
            />
          </aside>
        </div>
      )}

      <BottomNav screen={activeScreen} onScreen={setScreen} reviewCount={review.length} />

      <input
        ref={fileInput}
        type="file"
        accept=".txt,.csv,text/plain,text/csv"
        hidden
        onChange={(event) => {
          const file = event.target.files?.[0]
          if (file) void importFile(file)
          event.currentTarget.value = ''
        }}
      />
      {toast && (
        <button type="button" className="toast" onClick={() => setToast(null)}>
          {toast}
        </button>
      )}
      {modal === 'search' && (
        <SearchPalette
          data={data}
          index={wordIndex}
          progress={progress}
          lists={mixedLists}
          wordCount={countForList}
          onClose={() => setModal(null)}
          onTile={(tile) => { selectTile(tile); setModal(null) }}
          onList={(list) => { selectMixed(list); setModal(null) }}
          onWord={openSearchWord}
        />
      )}
      {modal === 'practice' && (
        <PracticeModal
          pairs={data.pairs.pairs}
          us={data.us}
          uk={data.uk}
          ipaMode={settings.ipaMode}
          onClose={() => setModal(null)}
          onPlay={speakWord}
          onQuiz={recordQuiz}
        />
      )}
      {modal === 'coach' && coachTile && (
        <CoachModal
          tile={coachTile}
          components={coachComponents}
          articulation={data.articulation}
          samples={coachSamples}
          us={data.us}
          uk={data.uk}
          ipaMode={settings.ipaMode}
          targets={coachTile.targets}
          kind={coachTile.kind}
          onClose={() => setModal(null)}
          onPlay={speakWord}
          onRecord={() => setModal('record')}
        />
      )}
      {modal === 'settings' && (
        <SettingsModal
          settings={settings}
          voices={speech.voices}
          onChange={(next) => setSettings(next)}
          onSource={(next) => { stopPlayback(); setSource(next) }}
          onResetProgress={resetProgress}
          onResetSettings={resetSettings}
          onClose={() => setModal(null)}
          onCredits={() => setModal('credits')}
        />
      )}
      {modal === 'credits' && (
        <CreditsModal provenance={data.provenance} onClose={() => setModal(null)} />
      )}
      {modal === 'record' && currentWord && (
        <RecordDialog
          word={currentWord}
          parts={parts}
          onPlay={() => speakWord(currentWord)}
          onSlow={() => speakWord(currentWord, true)}
          onClose={() => setModal(null)}
        />
      )}
    </div>
  )
}

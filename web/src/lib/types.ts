export interface AppInfo {
  name: string
  tagline: string
  dataLicense: string
  codeLicense: string
}

export interface SoundTile {
  id: string
  label: string
  exampleWord: string
  listKey: string
  group: 'single' | 'blend' | 'vowel'
  kind: 'onset' | 'blend' | 'coda' | 'codaBlend' | 'vowel'
  targets: string[]
}

export interface SoundCategory {
  id: 'starting' | 'vowel' | 'ending'
  title: string
  tiles: SoundTile[]
}

export interface MixedList {
  id: string
  title: string
  source: string
  author: string
  license: string
  url: string
}

export interface Library {
  app: AppInfo
  categories: SoundCategory[]
  mixed: MixedList[]
  lists: Record<string, string[]>
}

export interface PatternLists {
  source: string
  license: string
  limit: number
  lists: Record<string, string[]>
}

export interface MinimalPair {
  id: string
  a: string
  b: string
  focus: string
}

export interface MinimalPairBundle {
  source: string
  license: string
  pairs: MinimalPair[]
}

export type Contact =
  | 'none' | 'lips' | 'teeth' | 'betweenTeeth' | 'alveolar'
  | 'postAlveolar' | 'palatal' | 'velar' | 'glottal'

export type Airflow = 'none' | 'center' | 'side' | 'nasal' | 'stop'

export interface MouthShape {
  tip: number
  body: number
  back: number
  lipRound: number
  jaw: number
  contact: Contact
  airflow: Airflow
  voiced: boolean
}

export interface ArticulationError {
  heardAs: string
  fix: string
}

export interface Articulation {
  id: string
  symbol: string
  name: string
  place: string
  manner: string
  voiced: boolean
  steps: string[]
  errors: ArticulationError[]
  anchors: string[]
  shape: MouthShape
  glide: MouthShape | null
  isVowel: boolean
  anchorWord: string | null
  contrasts: string[]
  lengthLabel: 'short' | 'long' | 'glide' | null
}

export interface ProvenanceSource {
  name: string
  url?: string
  commit?: string
  file?: string
  sha256?: string
  license: string
  note?: string
}

export interface Provenance {
  generated: string
  dataLicense: string
  codeLicense: string
  sources: ProvenanceSource[]
}

export interface AppData {
  library: Library
  us: Record<string, string>
  uk: Record<string, string>
  patterns: PatternLists
  pairs: MinimalPairBundle
  articulation: Articulation[]
  provenance: Provenance
}

export type ListSource = 'curated' | 'built'
export type IpaMode = 'both' | 'us' | 'uk'
export type SearchFilter = 'all' | 'favorites' | 'trouble' | 'due'

export interface WordProgress {
  word: string
  listens: number
  correct: number
  wrong: number
  step: number
  due: number | null
  favorite: boolean
  trouble: boolean
  lastSeen: number | null
}

export interface WordHit {
  id: string
  word: string
  listID: string
  tileID: string | null
  listTitle: string
  index: number
}

export interface ImportedList {
  id: string
  title: string
  words: string[]
  source: string
}

export interface SearchResults {
  tiles: SoundTile[]
  lists: MixedList[]
  words: WordHit[]
}

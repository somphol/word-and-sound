import type { AppData, Articulation, SoundTile } from './types'

const base = import.meta.env.BASE_URL

async function load<T>(name: string): Promise<T> {
  const response = await fetch(`${base}data/${name}.json`)
  if (!response.ok) throw new Error(`Could not load ${name}.json (${response.status})`)
  return response.json() as Promise<T>
}

export async function loadData(): Promise<AppData> {
  const [library, us, uk, patterns, pairs, articulation, provenance] = await Promise.all([
    load<AppData['library']>('library'),
    load<Record<string, string>>('phonetics_us'),
    load<Record<string, string>>('phonetics_uk'),
    load<AppData['patterns']>('pattern_lists'),
    load<AppData['pairs']>('minimal_pairs'),
    load<Articulation[]>('articulation'),
    load<AppData['provenance']>('provenance'),
  ])
  return { library, us, uk, patterns, pairs, articulation, provenance }
}

const labelMap: Record<string, string> = {
  'æ/a': 'æ',
  'oʊ/əʊ': 'əʊ',
  'əː': 'ɜː',
  'ʌɪ': 'aɪ',
}

const blends: Record<string, string[]> = {
  fj: ['f', 'j'], nj: ['n', 'j'], 'θr': ['θ', 'r'], tr: ['t', 'r'], bl: ['b', 'l'], str: ['s', 't', 'r'],
  br: ['b', 'r'], dr: ['d', 'r'], dw: ['d', 'w'], fr: ['f', 'r'], gl: ['g', 'l'], gr: ['g', 'r'],
  gw: ['g', 'w'], hj: ['h', 'j'], kl: ['k', 'l'], kr: ['k', 'r'], kw: ['k', 'w'], lj: ['l', 'j'],
  mj: ['m', 'j'], pl: ['p', 'l'], pr: ['p', 'r'], sk: ['s', 'k'], skr: ['s', 'k', 'r'],
  skw: ['s', 'k', 'w'], sl: ['s', 'l'], sm: ['s', 'm'], sn: ['s', 'n'], sp: ['s', 'p'],
  spl: ['s', 'p', 'l'], spr: ['s', 'p', 'r'], st: ['s', 't'], sw: ['s', 'w'], tw: ['t', 'w'],
  vj: ['v', 'j'], 'ʃr': ['ʃ', 'r'], kt: ['k', 't'], lm: ['l', 'm'], dz: ['d', 'z'],
  ks: ['k', 's'], kst: ['k', 's', 't'], ld: ['l', 'd'], lf: ['l', 'f'], lk: ['l', 'k'],
  lp: ['l', 'p'], ls: ['l', 's'], lt: ['l', 't'], lz: ['l', 'z'], mf: ['m', 'f'],
  mp: ['m', 'p'], mpt: ['m', 'p', 't'], mz: ['m', 'z'], nd: ['n', 'd'], ns: ['n', 's'],
  nt: ['n', 't'], nts: ['n', 't', 's'], nz: ['n', 'z'], ps: ['p', 's'], pt: ['p', 't'],
  ts: ['t', 's'], 'ðd': ['ð', 'd'], 'ŋk': ['ŋ', 'k'], 'ŋz': ['ŋ', 'z'],
  'ŋθ': ['ŋ', 'θ'], 'ʃt': ['ʃ', 't'], 'ʒd': ['ʒ', 'd'],
}

export function componentIDs(label: string): string[] {
  return blends[label] ?? [labelMap[label] ?? label]
}

export function componentsFor(label: string, articulation: Articulation[]): Articulation[] {
  const byID = new Map(articulation.map((entry) => [entry.id, entry]))
  return componentIDs(label).map((id) => byID.get(id)).filter(Boolean) as Articulation[]
}

export function allTiles(library: AppData['library']): SoundTile[] {
  return library.categories.flatMap((category) => category.tiles)
}

export function categoryForTile(library: AppData['library'], tileID: string) {
  return library.categories.find((category) => category.tiles.some((tile) => tile.id === tileID))
}

export function wordsForTile(data: AppData, tile: SoundTile, source: 'curated' | 'built'): string[] {
  if (source === 'built' && data.patterns.lists[tile.id]?.length) return data.patterns.lists[tile.id]
  return data.library.lists[tile.listKey] ?? []
}

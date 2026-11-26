// Web Speech spells unknown consonant-only tokens letter by letter
// ("hmph" -> H-M-P-H). Give it a respelling, but keep the UI word intact.
const spoken: Record<string, string> = {
  hmph: 'humph',
  hm: 'hmm',
  hmm: 'hmm',
  mm: 'mm',
  mmm: 'mmm',
  'mm-hm': 'mm-hmm',
  'mm-hmm': 'mm-hmm',
  'mm-mm': 'mm-mm',
  'mmm-hmm': 'mmm-hmm',
  sh: 'shh',
  shh: 'shh',
  shhh: 'shh',
  psst: 'pssst',
  tsk: 'tisk',
  mph: 'miles per hour',
  km: 'kilometres',
  mr: 'mister',
  mrs: 'missus',
  ms: 'miz',
  dr: 'doctor',
  jr: 'junior',
}

export function spokenWord(word: string): string {
  return spoken[word.toLowerCase()] ?? word
}

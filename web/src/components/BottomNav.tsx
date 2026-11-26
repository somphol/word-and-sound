import { Icon, type IconName } from './Icon'

export type Screen = 'practice' | 'sounds' | 'words'

const items: Array<{ id: Screen; label: string; icon: IconName }> = [
  { id: 'practice', label: 'Practice', icon: 'sparkle' },
  { id: 'sounds', label: 'Sounds', icon: 'grid' },
  { id: 'words', label: 'Words', icon: 'list' },
]

export function BottomNav({
  screen,
  onScreen,
  reviewCount,
}: {
  screen: Screen
  onScreen: (screen: Screen) => void
  reviewCount: number
}) {
  return (
    <nav className="bottom-nav" aria-label="Sections">
      {items.map((item) => (
        <button
          key={item.id}
          type="button"
          className={screen === item.id ? 'active' : ''}
          aria-current={screen === item.id ? 'page' : undefined}
          onClick={() => onScreen(item.id)}
        >
          <span className="bottom-nav-icon">
            <Icon name={item.icon} size={21} />
            {item.id === 'words' && reviewCount > 0 && <span className="bottom-nav-badge">{reviewCount}</span>}
          </span>
          <span>{item.label}</span>
        </button>
      ))}
    </nav>
  )
}

import type { ReactNode } from 'react'

export type IconName =
  | 'search' | 'play' | 'pause' | 'previous' | 'next' | 'replay' | 'slow'
  | 'coach' | 'mic' | 'star' | 'flag' | 'settings' | 'upload' | 'info'
  | 'close' | 'chevronRight' | 'sun' | 'moon' | 'monitor' | 'check'
  | 'trash' | 'sparkle' | 'speaker' | 'list' | 'grid' | 'refresh'

const paths: Record<IconName, ReactNode> = {
  search: (
    <>
      <circle cx="11" cy="11" r="7" />
      <path d="M16.5 16.5 21 21" />
    </>
  ),
  play: <path d="M8 5.5v13l10.5-6.5Z" fill="currentColor" stroke="none" />,
  pause: (
    <>
      <rect x="7" y="5" width="3.5" height="14" rx="1.2" fill="currentColor" stroke="none" />
      <rect x="13.5" y="5" width="3.5" height="14" rx="1.2" fill="currentColor" stroke="none" />
    </>
  ),
  previous: (
    <>
      <path d="M18.5 6v12L9.5 12Z" fill="currentColor" stroke="none" />
      <path d="M5.5 6v12" />
    </>
  ),
  next: (
    <>
      <path d="M5.5 6v12L14.5 12Z" fill="currentColor" stroke="none" />
      <path d="M18.5 6v12" />
    </>
  ),
  replay: (
    <>
      <path d="M20 12a8 8 0 1 1-2.4-5.7" />
      <path d="M20 4.5V10h-5.5" />
    </>
  ),
  slow: (
    <>
      <path d="M4.5 18a8 8 0 1 1 15 0" />
      <path d="M12 14l3-3.5" />
      <circle cx="12" cy="14" r="1.2" fill="currentColor" stroke="none" />
    </>
  ),
  coach: (
    <>
      <path d="M3.5 11.5c2.2-3.1 5.2-4.6 8.5-4.6s6.3 1.5 8.5 4.6c-2.2 3.1-5.2 4.9-8.5 4.9s-6.3-1.8-8.5-4.9Z" />
      <path d="M8 12.2c1.4.9 2.7 1.3 4 1.3s2.6-.4 4-1.3" />
    </>
  ),
  mic: (
    <>
      <rect x="9" y="3" width="6" height="11" rx="3" />
      <path d="M5.5 11a6.5 6.5 0 0 0 13 0" />
      <path d="M12 17.5V21M8.5 21h7" />
    </>
  ),
  star: (
    <path d="m12 3.6 2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8L3.5 9.8l5.9-.9Z" />
  ),
  flag: (
    <>
      <path d="M5.5 21V4" />
      <path d="M5.5 4.5c3.6-1.8 7 1.8 13 0v9.5c-6 1.8-9.4-1.8-13 0" />
    </>
  ),
  settings: (
    <>
      <path d="M4 7h9M18 7h2M4 12h3M12 12h8M4 17h9M18 17h2" />
      <circle cx="15.5" cy="7" r="2.2" />
      <circle cx="9.5" cy="12" r="2.2" />
      <circle cx="15.5" cy="17" r="2.2" />
    </>
  ),
  upload: (
    <>
      <path d="M12 15.5V4M7.5 8.5 12 4l4.5 4.5" />
      <path d="M4.5 15.5V19a1.5 1.5 0 0 0 1.5 1.5h12a1.5 1.5 0 0 0 1.5-1.5v-3.5" />
    </>
  ),
  info: (
    <>
      <circle cx="12" cy="12" r="8.5" />
      <path d="M12 11v5.5" />
      <circle cx="12" cy="7.8" r="1" fill="currentColor" stroke="none" />
    </>
  ),
  close: <path d="M6 6l12 12M18 6 6 18" />,
  chevronRight: <path d="m9.5 6 6 6-6 6" />,
  sun: (
    <>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4M18.8 5.2l-1.4 1.4M6.6 17.4 5.2 18.8" />
    </>
  ),
  moon: <path d="M20.5 13.2A8.6 8.6 0 1 1 10.8 3.5a7 7 0 0 0 9.7 9.7Z" />,
  monitor: (
    <>
      <rect x="3" y="4.5" width="18" height="12" rx="2" />
      <path d="M9 20.5h6M12 16.5v4" />
    </>
  ),
  check: <path d="m5 12.5 4.5 4.5L19 6.5" />,
  trash: (
    <>
      <path d="M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13" />
      <path d="M10 11v5M14 11v5" />
    </>
  ),
  sparkle: (
    <path d="m12 3.5 1.9 5.3 5.3 1.9-5.3 1.9L12 18l-1.9-5.4-5.3-1.9 5.3-1.9Z" />
  ),
  speaker: (
    <>
      <path d="M11 5.5 6.5 9H3.5v6h3L11 18.5Z" />
      <path d="M15 9.2a3.8 3.8 0 0 1 0 5.6M17.8 6.8a7.2 7.2 0 0 1 0 10.4" />
    </>
  ),
  list: (
    <>
      <path d="M9 6h11M9 12h11M9 18h11" />
      <circle cx="4.6" cy="6" r="1" fill="currentColor" stroke="none" />
      <circle cx="4.6" cy="12" r="1" fill="currentColor" stroke="none" />
      <circle cx="4.6" cy="18" r="1" fill="currentColor" stroke="none" />
    </>
  ),
  grid: (
    <>
      <rect x="4" y="4" width="6.5" height="6.5" rx="1.6" />
      <rect x="13.5" y="4" width="6.5" height="6.5" rx="1.6" />
      <rect x="4" y="13.5" width="6.5" height="6.5" rx="1.6" />
      <rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.6" />
    </>
  ),
  refresh: (
    <>
      <path d="M20 12a8 8 0 0 1-13.6 5.6" />
      <path d="M4 12a8 8 0 0 1 13.6-5.6" />
      <path d="M17.6 2.9v3.6h-3.6" />
      <path d="M6.4 21.1v-3.6h3.6" />
    </>
  ),
}

export function Icon({
  name,
  size = 18,
  filled = false,
  className = '',
}: {
  name: IconName
  size?: number
  filled?: boolean
  className?: string
}) {
  return (
    <svg
      className={`icon ${className}`.trim()}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {paths[name]}
    </svg>
  )
}

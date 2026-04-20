interface NavbarProps {
  darkMode: boolean
  setDarkMode: (v: boolean) => void
}

export default function Navbar({ darkMode, setDarkMode }: NavbarProps) {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-apple-gray-50/80 dark:bg-apple-gray-800/80 backdrop-blur-md border-b border-apple-gray-200 dark:border-apple-gray-700 transition-colors duration-300">
      <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center gap-3">
          <img src="/logo.png" alt="DroidProxy" className="w-8 h-8" />
          <span className="text-xl font-semibold tracking-tight">DroidProxy</span>
        </div>

        {/* Nav links */}
        <div className="hidden md:flex items-center gap-8">
          <a href="#features" className="nav-link text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50">
            Features
          </a>
          <a href="#architecture" className="nav-link text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50">
            Architecture
          </a>
          <a href="#setup" className="nav-link text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50">
            Setup
          </a>
          <a
            href="https://github.com/anand-92/droidproxy"
            target="_blank"
            rel="noopener noreferrer"
            className="nav-link text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50"
          >
            GitHub
          </a>
        </div>

        {/* Dark mode toggle */}
        <button
          onClick={() => setDarkMode(!darkMode)}
          aria-pressed={darkMode}
          className="btn-press p-2 rounded-lg bg-apple-gray-100 dark:bg-apple-gray-700 hover:bg-apple-gray-200 dark:hover:bg-apple-gray-600 transition-colors"
          aria-label="Toggle dark mode"
        >
          <div className="toggle-icon">
            {darkMode ? (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            ) : (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
            )}
          </div>
        </button>
      </div>
    </nav>
  )
}

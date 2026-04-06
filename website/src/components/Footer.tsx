export default function Footer() {
  return (
    <footer className="py-12 px-6 border-t border-apple-gray-200 dark:border-apple-gray-700">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <img src="/logo.png" alt="DroidProxy" className="w-8 h-8" />
            <div>
              <div className="font-semibold">DroidProxy</div>
              <div className="text-xs text-apple-gray-400 dark:text-apple-gray-500">Open Source MIT License</div>
            </div>
          </div>

          <div className="flex items-center gap-6">
            <a
              href="https://github.com/anand-92/droidproxy"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50 transition-colors"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
              </svg>
              GitHub
            </a>
            <a
              href="https://github.com/anand-92/droidproxy/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50 transition-colors"
            >
              Issues
            </a>
            <a
              href="https://github.com/anand-92/droidproxy/blob/main/LICENSE"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-apple-gray-500 dark:text-apple-gray-400 hover:text-apple-gray-800 dark:hover:text-apple-gray-50 transition-colors"
            >
              License
            </a>
          </div>
        </div>
      </div>
    </footer>
  )
}

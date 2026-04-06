export default function Setup() {
  return (
    <section id="setup" className="py-20 px-6 bg-white dark:bg-apple-gray-700/30">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold tracking-tight mb-4">Get Started</h2>
          <p className="text-apple-gray-500 dark:text-apple-gray-400 max-w-2xl mx-auto">
            Download, install, and start proxying in under a minute.
          </p>
        </div>

        <div className="max-w-2xl mx-auto">
          <div className="space-y-6">
            <div className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700">
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center font-semibold text-sm">1</div>
                <div>
                  <h4 className="font-medium mb-2">Download the Latest Release</h4>
                  <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-3">
                    Grab the DMG from the GitHub releases page.
                  </p>
                  <a
                    href="https://github.com/anand-92/droidproxy/releases"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-500 text-white text-sm font-medium hover:bg-blue-600 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    Download from GitHub
                  </a>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700">
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center font-semibold text-sm">2</div>
                <div>
                  <h4 className="font-medium mb-2">Open Menu Bar Settings</h4>
                  <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-3">
                    Click the DroidProxy icon in your menu bar and open Settings.
                  </p>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700">
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center font-semibold text-sm">3</div>
                <div>
                  <h4 className="font-medium mb-2">Sign into Your Providers</h4>
                  <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-3">
                    Enter your API keys for Claude, Codex, or Gemini in the provider settings.
                  </p>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700">
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center font-semibold text-sm">4</div>
                <div>
                  <h4 className="font-medium mb-2">Apply Factory Custom Models</h4>
                  <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-3">
                    Click <strong>Apply</strong> to load the pre-configured factory custom models into your AI client settings.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-12">
            <h3 className="text-xl font-semibold mb-6 text-center">Factory Custom Models Reference</h3>
            <div className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700">
              <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-4">
                When you click Apply, DroidProxy registers these pre-configured custom models with your AI client, routing all requests through the local proxy at <code className="px-1.5 py-0.5 rounded bg-apple-gray-200 dark:bg-apple-gray-700 text-xs">localhost:8317</code>.
              </p>
              <div className="p-4 rounded-lg bg-apple-gray-100 dark:bg-apple-gray-900 code-block overflow-x-auto">
                <pre className="text-xs leading-relaxed">{`"customModels": [
  {
    "model": "claude-opus-4-6",
    "id": "custom:droidproxy:opus-4-6",
    "index": 0,
    "baseUrl": "http://localhost:8317",
    "apiKey": "***",
    "displayName": "DroidProxy: Opus 4.6",
    "maxOutputTokens": 128000,
    "provider": "anthropic"
  },
  {
    "model": "claude-sonnet-4-6",
    "id": "custom:droidproxy:sonnet-4-6",
    "index": 1,
    "baseUrl": "http://localhost:8317",
    "apiKey": "***",
    "displayName": "DroidProxy: Sonnet 4.6",
    "maxOutputTokens": 64000,
    "provider": "anthropic"
  },
  {
    "model": "gpt-5.3-codex",
    "id": "custom:droidproxy:gpt-5.3-codex",
    "index": 2,
    "baseUrl": "http://localhost:8317/v1",
    "apiKey": "***",
    "displayName": "DroidProxy: GPT 5.3 Codex",
    "maxOutputTokens": 128000,
    "provider": "openai"
  },
  {
    "model": "gpt-5.4",
    "id": "custom:droidproxy:gpt-5.4",
    "index": 3,
    "baseUrl": "http://localhost:8317/v1",
    "apiKey": "***",
    "displayName": "DroidProxy: GPT 5.4",
    "maxOutputTokens": 128000,
    "provider": "openai"
  },
  {
    "model": "gemini-3.1-pro-preview",
    "id": "custom:droidproxy:gemini-3.1-pro",
    "index": 4,
    "baseUrl": "http://localhost:8317/v1",
    "apiKey": "***",
    "displayName": "DroidProxy: Gemini 3.1 Pro",
    "maxOutputTokens": 65536,
    "provider": "openai"
  },
  {
    "model": "gemini-3-flash-preview",
    "id": "custom:droidproxy:gemini-3-flash",
    "index": 5,
    "baseUrl": "http://localhost:8317/v1",
    "apiKey": "***",
    "displayName": "DroidProxy: Gemini 3 Flash",
    "maxOutputTokens": 65536,
    "provider": "openai"
  }
]`}</pre>
              </div>
            </div>
          </div>

          <div className="mt-8 flex items-center justify-center gap-4">
            <img src="/factory-logo.svg" alt="Factory.ai" className="h-8 opacity-60" />
            <span className="text-sm text-apple-gray-400">Compatible with Factory.ai Droids</span>
          </div>
        </div>
      </div>
    </section>
  )
}
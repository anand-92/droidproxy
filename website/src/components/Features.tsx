import ProviderIcons from './ProviderIcons'

const features = [
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    ),
    title: 'One-Click OAuth',
    description: 'Authenticate with Claude Code, Codex, and Gemini instantly from your menu bar. No terminal commands or manual token handling.'
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
    ),
    title: 'Adaptive Thinking Proxy',
    description: 'Automatically injects thinking: {"type":"adaptive"} and output_config.effort for enhanced reasoning capabilities.'
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
      </svg>
    ),
    title: 'Per-Model Effort Controls',
    description: 'Fine-tune response quality vs speed with model-specific effort settings. Opus 4.7, Sonnet 4.6, GPT 5.3 Codex, GPT 5.4, Gemini 3.1 Pro, and Gemini 3 Flash supported.'
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
      </svg>
    ),
    title: 'Sparkle Auto-Updates',
    description: 'Stay up-to-date with seamless background updates. Never miss a new feature or security patch.'
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>
    ),
    title: 'Factory.ai Integration',
    description: 'Connects to localhost:8317 for seamless integration with Factory.ai Droids and other AI coding tools.'
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
      </svg>
    ),
    title: 'Menu Bar App',
    description: 'Runs discreetly in your menu bar. Quick access to settings, status, and authentication controls.'
  }
]

export default function Features() {
  return (
    <section id="features" className="py-20 px-6 bg-white dark:bg-apple-gray-700/30">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold tracking-tight mb-4">Powerful Features</h2>
          <p className="text-apple-gray-500 dark:text-apple-gray-400 max-w-2xl mx-auto">
            Everything you need to proxy and manage AI coding tool authentication on macOS.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <div
              key={index}
              className="p-6 rounded-2xl bg-apple-gray-50 dark:bg-apple-gray-800/50 border border-apple-gray-200 dark:border-apple-gray-700 hover:border-blue-300 dark:hover:border-blue-600 transition-colors"
            >
              <div className="w-12 h-12 rounded-xl bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center mb-4">
                {feature.icon}
              </div>
              <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
              <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        <div className="mt-16 p-6 rounded-2xl bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 border border-apple-gray-200 dark:border-apple-gray-700">
          <div className="flex flex-col lg:flex-row items-center gap-6">
            <div className="flex-1">
              <h3 className="text-lg font-semibold mb-2">Per-Model Effort Controls</h3>
              <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400 mb-4">
                Customize response quality vs speed for each AI model:
              </p>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium">Opus 4.7</span>
                  <span className="text-apple-gray-400 ml-2">low / medium / high / xhigh / max</span>
                </div>
                <div>
                  <span className="font-medium">Sonnet 4.6</span>
                  <span className="text-apple-gray-400 ml-2">low / medium / high / max</span>
                </div>
                <div>
                  <span className="font-medium">GPT 5.3 Codex</span>
                  <span className="text-apple-gray-400 ml-2">low / medium / high / xhigh</span>
                </div>
                <div>
                  <span className="font-medium">GPT 5.4</span>
                  <span className="text-apple-gray-400 ml-2">low / medium / high / xhigh</span>
                </div>
                <div>
                  <span className="font-medium">Gemini 3.1 Pro</span>
                  <span className="text-apple-gray-400 ml-2">low / medium / high</span>
                </div>
                <div>
                  <span className="font-medium">Gemini 3 Flash</span>
                  <span className="text-apple-gray-400 ml-2">minimal / low / medium / high</span>
                </div>
              </div>
            </div>
            <div className="w-full lg:w-80">
              <img
                src="/settings-screenshot.png"
                alt="DroidProxy Settings"
                className="rounded-xl shadow-lg"
              />
            </div>
          </div>
        </div>

        <div className="mt-16 text-center">
          <h3 className="text-lg font-semibold mb-6">Supported Providers</h3>
          <div className="flex flex-wrap items-center justify-center gap-8">
            <ProviderIcons />
          </div>
        </div>
      </div>
    </section>
  )
}
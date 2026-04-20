import { useEffect, useRef } from 'react'

export default function Hero() {
  const badgeRef = useRef<HTMLDivElement>(null)
  const titleRef = useRef<HTMLHeadingElement>(null)
  const subtitleRef = useRef<HTMLParagraphElement>(null)
  const descriptionRef = useRef<HTMLParagraphElement>(null)
  const ctaRef = useRef<HTMLDivElement>(null)
  const statsRef = useRef<HTMLDivElement>(null)
  const imageRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Staggered entrance: badge -> title -> subtitle -> description -> CTA -> stats -> image
    // imageRef delay (600ms) must be last so it animates after statsRef (500ms)
    const elements = [
      { ref: badgeRef, delay: 0 },
      { ref: titleRef, delay: 100 },
      { ref: subtitleRef, delay: 200 },
      { ref: descriptionRef, delay: 300 },
      { ref: ctaRef, delay: 400 },
      { ref: statsRef, delay: 500 },
      { ref: imageRef, delay: 600 },
    ]

    elements.forEach(({ ref, delay }) => {
      if (ref.current) {
        ref.current.style.opacity = '0'
        ref.current.style.transform = 'translateY(20px)'
        ref.current.style.transition = `opacity 0.5s cubic-bezier(0.25, 1, 0.5, 1) ${delay}ms, transform 0.5s cubic-bezier(0.25, 1, 0.5, 1) ${delay}ms`

        requestAnimationFrame(() => {
          if (ref.current) {
            ref.current.style.opacity = '1'
            ref.current.style.transform = 'translateY(0)'
          }
        })
      }
    })
  }, [])

  return (
    <section className="pt-32 pb-20 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col lg:flex-row items-center gap-12">
          {/* Text content */}
          <div className="flex-1 text-center lg:text-left">
            {/* Badge */}
            <div ref={badgeRef}>
              <div className="badge-shimmer inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-sm font-medium mb-6">
                <span className="w-2 h-2 rounded-full bg-blue-500 pulse-dot"></span>
                Open Source
              </div>
            </div>

            {/* Title */}
            <h1
              ref={titleRef}
              className="text-5xl lg:text-6xl font-bold tracking-tight mb-6 bg-gradient-to-r from-apple-gray-800 dark:from-white to-apple-gray-500 dark:to-apple-gray-400 bg-clip-text text-transparent"
            >
              DroidProxy
            </h1>

            {/* Subtitle */}
            <p
              ref={subtitleRef}
              className="text-xl lg:text-2xl text-apple-gray-500 dark:text-apple-gray-400 mb-4 leading-relaxed"
            >
              One-click OAuth proxy for Claude Code, Codex &amp; Gemini
            </p>

            {/* Description */}
            <p
              ref={descriptionRef}
              className="text-base text-apple-gray-400 dark:text-apple-gray-500 mb-8 max-w-lg mx-auto lg:mx-0"
            >
              A native macOS menu bar app that proxies authentication for AI coding tools. Built on CLIProxyAPIPlus with adaptive thinking, per-model effort controls, and Sparkle auto-updates.
            </p>

            {/* CTA Buttons */}
            <div ref={ctaRef} className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <a
                href="#setup"
                className="cta-glow btn-press px-8 py-3 bg-apple-gray-800 dark:bg-white text-white dark:text-apple-gray-800 rounded-lg font-medium hover:bg-apple-gray-700 dark:hover:bg-apple-gray-100 transition-colors text-center"
              >
                Get Started
              </a>
              <a
                href="https://github.com/anand-92/droidproxy"
                target="_blank"
                rel="noopener noreferrer"
                className="btn-press px-8 py-3 bg-apple-gray-100 dark:bg-apple-gray-700 text-apple-gray-800 dark:text-apple-gray-100 rounded-lg font-medium hover:bg-apple-gray-200 dark:hover:bg-apple-gray-600 transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                </svg>
                View on GitHub
              </a>
            </div>

            {/* Stats */}
            <div ref={statsRef} className="mt-10 flex flex-wrap gap-6 justify-center lg:justify-start text-sm text-apple-gray-400 dark:text-apple-gray-500">
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                macOS 13.0+
              </div>
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                Apple Silicon
              </div>
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                MIT License
              </div>
            </div>
          </div>

          {/* Hero image — delay 600ms so it animates after stats at 500ms */}
          <div ref={imageRef} className="flex-1 flex justify-center">
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-purple-500 rounded-2xl blur-3xl opacity-20 dark:opacity-30"></div>
              <img
                src="/logo.png"
                alt="DroidProxy"
                className="relative w-64 h-64 lg:w-80 lg:h-80 object-contain logo-float"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

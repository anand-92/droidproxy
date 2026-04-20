import { useInViewOnce } from '../hooks/useInViewOnce'

interface Step {
  iconBg: string
  iconBgDark: string
  iconText: string
  iconTextDark: string
  iconBorder: string
  iconBorderDark: string
  icon: React.ReactNode
  title: string
  description: string
}

const steps: Step[] = [
  {
    iconBg: 'bg-blue-100',
    iconBgDark: 'dark:bg-blue-900/30',
    iconText: 'text-blue-600',
    iconTextDark: 'dark:text-blue-400',
    iconBorder: 'border-blue-500',
    iconBorderDark: 'dark:border-blue-600',
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>
    ),
    title: '1. AI Coding Tool',
    description: 'Your AI coding tool (Factory.ai Droid, Claude Code, etc.) sends requests configured to use localhost:8317'
  },
  {
    iconBg: 'bg-purple-100',
    iconBgDark: 'dark:bg-purple-900/30',
    iconText: 'text-purple-600',
    iconTextDark: 'dark:text-purple-400',
    iconBorder: 'border-purple-500',
    iconBorderDark: 'dark:border-purple-600',
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    ),
    title: '2. ThinkingProxy (localhost:8317)',
    description: 'User-facing TCP proxy that injects adaptive thinking parameters and routes requests intelligently'
  },
  {
    iconBg: 'bg-green-100',
    iconBgDark: 'dark:bg-green-900/30',
    iconText: 'text-green-600',
    iconTextDark: 'dark:text-green-400',
    iconBorder: 'border-green-500',
    iconBorderDark: 'dark:border-green-600',
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" />
      </svg>
    ),
    title: '3. CLIProxyAPIPlus (127.0.0.1:8318)',
    description: 'Child process managed by ServerManager. Handles OAuth authentication and API communication with upstream providers'
  },
  {
    iconBg: 'bg-orange-100',
    iconBgDark: 'dark:bg-orange-900/30',
    iconText: 'text-orange-600',
    iconTextDark: 'dark:text-orange-400',
    iconBorder: 'border-orange-500',
    iconBorderDark: 'dark:border-orange-600',
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z" />
      </svg>
    ),
    title: '4. Upstream Providers',
    description: 'Claude Code (api.anthropic.com), Codex (api.openai.com), and other supported AI providers'
  }
]

export default function Architecture() {
  const { ref: sectionRef, isVisible } = useInViewOnce({ threshold: 0.15, rootMargin: '0px 0px -40px 0px' })

  return (
    <section ref={sectionRef} id="architecture" className="py-20 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold tracking-tight mb-4">How It Works</h2>
          <p className="text-apple-gray-500 dark:text-apple-gray-400 max-w-2xl mx-auto">
            DroidProxy sits between your AI coding tools and upstream providers, handling authentication and intelligent request routing.
          </p>
        </div>

        <div className="bg-white dark:bg-apple-gray-800/50 rounded-2xl p-8 border border-apple-gray-200 dark:border-apple-gray-700">
          <div className="flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="flex-1 w-full">
              <div className="relative">
                {/* Vertical timeline line */}
                <div className="absolute left-8 top-0 bottom-0 w-0.5 bg-apple-gray-200 dark:bg-apple-gray-600 hidden lg:block"></div>

                <div className="space-y-8">
                  {steps.map((step, index) => (
                    <div
                      key={index}
                      className={`relative flex items-start gap-6 transition-all duration-500 ${isVisible ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-4'}`}
                      style={{ transitionDelay: `${index * 120}ms` }}
                    >
                      {/* Icon circle — static classes, no runtime dark: concatenation */}
                      <div className={`flex-shrink-0 w-16 h-16 rounded-2xl ${step.iconBg} ${step.iconBgDark} flex items-center justify-center z-10 border-2 ${step.iconBorder} ${step.iconBorderDark}`}>
                        <span className={`${step.iconText} ${step.iconTextDark}`}>
                          {step.icon}
                        </span>
                      </div>

                      {/* Text content */}
                      <div className="flex-1 pt-2">
                        <h4 className="text-lg font-semibold mb-1">{step.title}</h4>
                        <p className="text-sm text-apple-gray-500 dark:text-apple-gray-400">
                          {step.description}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

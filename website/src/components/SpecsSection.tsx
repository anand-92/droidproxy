import { useSpecsAnimation } from '../animations/useSiteAnimations'

const specs = [
  { label: 'Platform', value: 'macOS 13.0+', small: 'Ventura · Sonoma · Sequoia' },
  { label: 'Architecture', value: 'Apple Silicon', small: 'M1 · M2 · M3 · M4' },
  { label: 'Local ports', value: '8317', small: ':8317/v1 · :8318 child', mono: true },
  { label: 'License', value: 'MIT', small: 'open source · free forever' },
  { label: 'Auto-update', value: 'Sparkle', small: 'EdDSA-signed appcast' },
  { label: 'Auth model', value: 'Native OAuth', small: 'no API keys to provision' },
  { label: 'Built on', value: 'CLIProxyAPIPlus', small: 'router-for-me · MIT' },
  { label: 'Distribution', value: 'Notarized .dmg', small: 'Sparkle delta updates' },
]

export default function SpecsSection() {
  const containerRef = useSpecsAnimation()

  return (
    <section id="specs" ref={containerRef}>
      <div className="container">
        <div className="section-head specs-head">
          <div>
            <div className="meta specs-meta">§ 05 — Spec sheet</div>
            <h2 className="specs-h2" style={{ marginTop: 10 }}>The boring numbers.</h2>
          </div>
          <p className="specs-p">Everything worth knowing about runtime, footprint, and licensing — at a glance, no marketing detour.</p>
        </div>

        <div className="specs">
          {specs.map((s) => (
            <div className="spec will-change-transform" key={s.label}>
              <div className="spec-label">{s.label}</div>
              <div className={`spec-value ${s.mono ? 'mono num' : ''}`}>
                {s.value}
                <small>{s.small}</small>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

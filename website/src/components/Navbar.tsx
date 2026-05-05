import { GitHubIcon } from './icons'
import { useNavbarAnimation } from '../animations/useSiteAnimations'

export default function Navbar() {
  const containerRef = useNavbarAnimation()

  return (
    <header className="nav" ref={containerRef}>
      <div className="container nav-inner">
        <a href="#" className="brand">
          <img src="/assets/logo.png" alt="" />
          <span>DroidProxy</span>
        </a>
        <nav className="nav-links">
          <a href="#use-cases">Why</a>
          <a href="#how-it-works">How it works</a>
          <a href="#models">Models</a>
          <a href="#install">Install</a>
          <a href="https://github.com/anand-92/droidproxy" target="_blank" rel="noopener">GitHub</a>
        </nav>
        <div className="nav-cta">
          <a
            href="https://github.com/anand-92/droidproxy"
            target="_blank"
            rel="noopener"
            className="btn btn-ghost"
            aria-label="GitHub"
          >
            <GitHubIcon />
            <span>Star</span>
          </a>
          <a
            href="https://github.com/anand-92/droidproxy/releases/latest"
            target="_blank"
            rel="noopener"
            className="btn btn-primary"
          >
            Download <span className="mono" style={{ opacity: 0.7, fontSize: 11, letterSpacing: '0.04em' }}>.dmg</span>
          </a>
        </div>
      </div>
    </header>
  )
}

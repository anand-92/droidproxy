import { DownloadIcon, GitHubIcon } from './icons'
import { useClosingAnimation } from '../animations/useSiteAnimations'

export default function ClosingCTA() {
  const containerRef = useClosingAnimation()

  return (
    <section className="closing" ref={containerRef}>
      <div className="container">
        <h2 className="closing-h2">Use Factory Droid on the subscriptions you already have.</h2>
        <p className="closing-p">Stop paying twice for the same models. Free, open source, signed by Apple, and small enough to live in your menu bar.</p>
        <div className="closing-cta">
          <a href="https://github.com/anand-92/droidproxy/releases/latest" className="btn btn-primary btn-lg" target="_blank" rel="noopener">
            Download for macOS
            <DownloadIcon />
          </a>
          <a href="https://github.com/anand-92/droidproxy" className="btn btn-ghost btn-lg" target="_blank" rel="noopener">
            <GitHubIcon />
            Read the source
          </a>
        </div>
      </div>
    </section>
  )
}

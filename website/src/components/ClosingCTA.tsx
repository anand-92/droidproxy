import { DownloadIcon, GitHubIcon } from './icons'

export default function ClosingCTA() {
  return (
    <section className="closing">
      <div className="container">
        <h2>Use Factory Droid on the subscriptions you already have.</h2>
        <p>Stop paying twice for the same models. Free, open source, signed by Apple, and small enough to live in your menu bar.</p>
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

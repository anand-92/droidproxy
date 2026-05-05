import { useModelsAnimation } from '../animations/useSiteAnimations'
import { Claude, Codex, Gemini } from '@lobehub/icons'

const models = [
  {
    Icon: Claude.Color,
    name: 'Claude Opus 4.7',
    id: 'opus-4-7',
    levels: ['low', 'medium', 'high', 'xhigh', 'max'],
    max: '128,000',
    provider: 'Anthropic',
  },
  {
    Icon: Claude.Color,
    name: 'Claude Sonnet 4.6',
    id: 'sonnet-4-6',
    levels: ['low', 'medium', 'high', 'max'],
    max: '64,000',
    provider: 'Anthropic',
  },
  {
    Icon: Codex.Color,
    name: 'GPT 5.3 Codex',
    id: 'gpt-5.3-codex',
    levels: ['low', 'medium', 'high', 'xhigh', 'fast'],
    max: '128,000',
    provider: 'OpenAI',
  },
  {
    Icon: Codex.Color,
    name: 'GPT 5.4',
    id: 'gpt-5.4',
    levels: ['low', 'medium', 'high', 'xhigh', 'fast'],
    max: '128,000',
    provider: 'OpenAI',
  },
  {
    Icon: Codex.Color,
    name: 'GPT 5.5',
    id: 'gpt-5.5',
    levels: ['low', 'medium', 'high', 'xhigh', 'fast'],
    max: '128,000',
    provider: 'OpenAI',
  },
  {
    Icon: Gemini.Color,
    name: 'Gemini 3.1 Pro',
    id: 'gemini-3.1-pro-preview',
    levels: ['low', 'medium', 'high'],
    max: '65,536',
    provider: 'Google',
  },
  {
    Icon: Gemini.Color,
    name: 'Gemini 3 Flash',
    id: 'gemini-3-flash-preview',
    levels: ['minimal', 'low', 'medium', 'high'],
    max: '65,536',
    provider: 'Google',
  },
]

export default function ModelsSection() {
  const containerRef = useModelsAnimation()

  return (
    <section id="models" ref={containerRef}>
      <div className="container">
        <div className="section-head models-head">
          <div>
            <div className="meta models-meta">§ 03 — Models</div>
            <h2 className="models-h2" style={{ marginTop: 10 }}>All the frontier models, your subscription.</h2>
          </div>
          <p className="models-p">Each model has a thinking dial — turn it up for harder problems, down for faster answers. Pick whichever models match the subscriptions you actually have.</p>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th style={{ width: '32%' }}>Model</th>
                <th>Effort levels</th>
                <th style={{ width: '18%' }}>Max output</th>
                <th style={{ width: '14%' }}>Provider</th>
              </tr>
            </thead>
            <tbody>
              {models.map((m) => (
                <tr key={m.id}>
                  <td className="model-cell">
                    <m.Icon size={18} />
                    <div>
                      <b>{m.name}</b>
                      <span>{m.id}</span>
                    </div>
                  </td>
                  <td>
                    <div className="levels">
                      {m.levels.map((lvl) => (
                        <span className={lvl === 'max' ? 'level max' : 'level'} key={lvl}>{lvl}</span>
                      ))}
                    </div>
                  </td>
                  <td className="ctx num">{m.max}<small>tok</small></td>
                  <td className="ctx">{m.provider}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}

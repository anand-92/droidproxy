export default function ProviderIcons() {
  return (
    <div className="flex flex-wrap items-center justify-center gap-8">
      <div className="flex flex-col items-center gap-2">
        <img src="/icon-claude.png" alt="Claude" className="w-12 h-12 object-contain" />
        <span className="text-sm font-medium text-apple-gray-600 dark:text-apple-gray-300">Claude</span>
      </div>
      <div className="flex flex-col items-center gap-2">
        <img src="/icon-codex.png" alt="Codex" className="w-12 h-12 object-contain" />
        <span className="text-sm font-medium text-apple-gray-600 dark:text-apple-gray-300">Codex</span>
      </div>
      <div className="flex flex-col items-center gap-2">
        <img src="/icon-gemini.png" alt="Gemini" className="w-12 h-12 object-contain" />
        <span className="text-sm font-medium text-apple-gray-600 dark:text-apple-gray-300">Gemini</span>
      </div>
    </div>
  )
}
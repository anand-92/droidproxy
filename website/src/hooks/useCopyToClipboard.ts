import { useCallback, useState } from 'react'

export function useCopyToClipboard() {
  const [copied, setCopied] = useState(false)

  const copy = useCallback((text: string) => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 1400)
    })
  }, [])

  return { copy, copied }
}

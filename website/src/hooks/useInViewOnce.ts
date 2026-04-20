import { useState, useEffect, useRef } from 'react'

export function useInViewOnce<T extends HTMLElement = HTMLElement>(
  options = { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
) {
  const ref = useRef<T>(null)
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    if (!ref.current) return

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsVisible(true)
        observer.disconnect()
      }
    }, options)

    observer.observe(ref.current)

    return () => observer.disconnect()
  }, [options.threshold, options.rootMargin])

  return { ref, isVisible }
}

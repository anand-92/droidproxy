import { useRef } from 'react'
import { useGSAP } from '@gsap/react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { SplitText } from 'gsap/SplitText'

gsap.registerPlugin(ScrollTrigger, SplitText)

/* ------------------------------------------------------------------ */
/*  1. Navbar                                                          */
/* ------------------------------------------------------------------ */
export function useNavbarAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.brand', { scale: 0.8, autoAlpha: 0, duration: 0.6, ease: 'back.out(1.7)' })
        gsap.from('.nav-links a', {
          y: -10,
          autoAlpha: 0,
          stagger: 0.05,
          duration: 0.5,
          ease: 'power2.out',
          delay: 0.15,
        })
        gsap.from('.nav-cta a', {
          scale: 0.9,
          autoAlpha: 0,
          stagger: 0.08,
          duration: 0.5,
          ease: 'back.out(1.4)',
          delay: 0.3,
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  2. HeroSection                                                     */
/* ------------------------------------------------------------------ */
export function useHeroAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        const tl = gsap.timeline({ defaults: { ease: 'power2.out' } })

        tl.from('.hero-eyebrow', { y: 12, autoAlpha: 0, duration: 0.6 })

        const splitTitle = SplitText.create('.hero-title', { type: 'words' })
        tl.from(
          splitTitle.words,
          { y: 40, autoAlpha: 0, rotateX: 15, stagger: 0.04, duration: 0.9, ease: 'power3.out' },
          '-=0.3'
        )

        tl.from('.hero-lede', { y: 20, autoAlpha: 0, duration: 0.7 }, '-=0.5')

        tl.from(
          '.hero-cta a',
          { scale: 0.92, autoAlpha: 0, stagger: 0.1, duration: 0.6, ease: 'back.out(1.4)' },
          '-=0.4'
        )

        tl.from(
          '.hero-meta span',
          { y: 12, autoAlpha: 0, stagger: 0.08, duration: 0.5 },
          '-=0.3'
        )

        tl.from(
          '.product-shot',
          { x: 60, autoAlpha: 0, scale: 0.96, duration: 1.1, ease: 'power2.out' },
          '-=0.9'
        )

        // Scroll parallax on screenshot
        gsap.to('.product-shot', {
          y: -30,
          ease: 'none',
          scrollTrigger: {
            trigger: '.hero',
            start: 'top top',
            end: 'bottom top',
            scrub: 1,
          },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  3. LogosStrip                                                      */
/* ------------------------------------------------------------------ */
export function useLogosAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.logos', { autoAlpha: 0, duration: 0.6, ease: 'power2.out' })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  4. UseCasesSection                                                 */
/* ------------------------------------------------------------------ */
export function useUseCasesAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        // Header
        gsap.from('.usecases-meta', { x: -30, autoAlpha: 0, duration: 0.6, ease: 'power2.out', scrollTrigger: { trigger: '.section-head', start: 'top 80%', once: true } })
        gsap.from('.usecases-h2', { y: 20, autoAlpha: 0, duration: 0.6, ease: 'power2.out', scrollTrigger: { trigger: '.section-head', start: 'top 80%', once: true } })
        gsap.from('.usecases-p', { y: 20, autoAlpha: 0, duration: 0.6, delay: 0.1, ease: 'power2.out', scrollTrigger: { trigger: '.section-head', start: 'top 80%', once: true } })

        // Cards batch
        ScrollTrigger.batch('.usecase', {
          start: 'top 85%',
          once: true,
          onEnter: (batch) => {
            gsap.from(batch, {
              y: 50,
              autoAlpha: 0,
              scale: 0.97,
              stagger: 0.12,
              duration: 0.7,
              ease: 'power2.out',
            })
          },
        })

        // Hover lift
        const cards = gsap.utils.toArray<HTMLElement>('.usecase')
        cards.forEach((card) => {
          const hover = gsap.to(card, { y: -4, duration: 0.25, ease: 'power2.out', paused: true })
          card.addEventListener('mouseenter', () => hover.play())
          card.addEventListener('mouseleave', () => hover.reverse())
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  5. HowItWorksSection                                               */
/* ------------------------------------------------------------------ */
export function useHowItWorksAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        // Header
        gsap.from('.hiw-meta', { x: -30, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.hiw-head', start: 'top 80%', once: true } })
        gsap.from('.hiw-h2', { y: 20, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.hiw-head', start: 'top 80%', once: true } })
        gsap.from('.hiw-p', { y: 20, autoAlpha: 0, duration: 0.6, delay: 0.1, scrollTrigger: { trigger: '.hiw-head', start: 'top 80%', once: true } })

        // Flow rows stagger
        gsap.from('.flow-row', {
          y: 30,
          autoAlpha: 0,
          stagger: 0.15,
          duration: 0.7,
          ease: 'power2.out',
          scrollTrigger: { trigger: '.flow', start: 'top 80%', once: true },
        })

        // Flow number pop
        gsap.from('.flow-num', {
          scale: 0,
          autoAlpha: 0,
          stagger: 0.15,
          duration: 0.5,
          ease: 'back.out(2)',
          delay: 0.2,
          scrollTrigger: { trigger: '.flow', start: 'top 80%', once: true },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  6. ModelsSection                                                   */
/* ------------------------------------------------------------------ */
export function useModelsAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.models-meta', { x: -30, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.models-head', start: 'top 80%', once: true } })
        gsap.from('.models-h2', { y: 20, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.models-head', start: 'top 80%', once: true } })
        gsap.from('.models-p', { y: 20, autoAlpha: 0, duration: 0.6, delay: 0.1, scrollTrigger: { trigger: '.models-head', start: 'top 80%', once: true } })

        ScrollTrigger.batch('tbody tr', {
          start: 'top 90%',
          once: true,
          onEnter: (batch) => {
            gsap.from(batch, {
              y: 20,
              autoAlpha: 0,
              stagger: 0.06,
              duration: 0.5,
              ease: 'power2.out',
            })
          },
        })

        ScrollTrigger.batch('.level', {
          start: 'top 90%',
          once: true,
          onEnter: (batch) => {
            gsap.from(batch, {
              scale: 0.8,
              autoAlpha: 0,
              y: 8,
              stagger: 0.02,
              duration: 0.4,
              ease: 'back.out(1.4)',
            })
          },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  7. MaxModeSection                                                  */
/* ------------------------------------------------------------------ */
export function useMaxModeAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        const tl = gsap.timeline({
          scrollTrigger: { trigger: containerRef.current, start: 'top 75%', once: true },
        })

        tl.from('.spot-pill', { y: 12, autoAlpha: 0, duration: 0.5, ease: 'power2.out' })

        const splitH2 = SplitText.create('.spotlight-h2', { type: 'words' })
        tl.from(splitH2.words, { y: 30, autoAlpha: 0, stagger: 0.04, duration: 0.7, ease: 'power3.out' }, '-=0.2')

        tl.from('.spotlight-p', { y: 20, autoAlpha: 0, duration: 0.6 }, '-=0.4')

        // dt / dd pairs stagger
        const dts = gsap.utils.toArray<HTMLElement>('.spot-list dt')
        const dds = gsap.utils.toArray<HTMLElement>('.spot-list dd')
        dts.forEach((dt, i) => {
          tl.from(dt, { x: -20, autoAlpha: 0, duration: 0.5 }, '-=0.3')
          if (dds[i]) {
            tl.from(dds[i], { x: 20, autoAlpha: 0, duration: 0.5 }, '<')
          }
        })

        tl.from(
          '.spot-shot',
          { x: 80, autoAlpha: 0, scale: 0.95, duration: 1, ease: 'power2.out' },
          '-=1.2'
        )
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  8. InstallSection                                                  */
/* ------------------------------------------------------------------ */
export function useInstallAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.install-meta', { x: -30, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.install-head', start: 'top 80%', once: true } })
        gsap.from('.install-h2', { y: 20, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.install-head', start: 'top 80%', once: true } })
        gsap.from('.install-p', { y: 20, autoAlpha: 0, duration: 0.6, delay: 0.1, scrollTrigger: { trigger: '.install-head', start: 'top 80%', once: true } })

        // Step numbers pop, then text fades
        const steps = gsap.utils.toArray<HTMLElement>('.step')
        steps.forEach((step, i) => {
          const st = gsap.timeline({
            scrollTrigger: { trigger: step, start: 'top 85%', once: true },
          })
          st.from(step.querySelector('.step-n'), { scale: 0, autoAlpha: 0, duration: 0.5, ease: 'back.out(2)' })
          st.from(
            step.querySelectorAll('h4, p, .step-cta'),
            { y: 16, autoAlpha: 0, stagger: 0.06, duration: 0.5, ease: 'power2.out' },
            '-=0.2'
          )
        })

        // Code block reveal
        gsap.from('.code-block', {
          y: 20,
          autoAlpha: 0,
          duration: 0.8,
          ease: 'power2.out',
          scrollTrigger: { trigger: '.code-block', start: 'top 85%', once: true },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  9. SpecsSection                                                    */
/* ------------------------------------------------------------------ */
export function useSpecsAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.specs-meta', { x: -30, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.specs-head', start: 'top 80%', once: true } })
        gsap.from('.specs-h2', { y: 20, autoAlpha: 0, duration: 0.6, scrollTrigger: { trigger: '.specs-head', start: 'top 80%', once: true } })
        gsap.from('.specs-p', { y: 20, autoAlpha: 0, duration: 0.6, delay: 0.1, scrollTrigger: { trigger: '.specs-head', start: 'top 80%', once: true } })

        ScrollTrigger.batch('.spec', {
          batchMax: 4,
          interval: 0.1,
          start: 'top 85%',
          once: true,
          onEnter: (batch) => {
            gsap.from(batch, {
              y: 30,
              autoAlpha: 0,
              scale: 0.96,
              stagger: 0.08,
              duration: 0.6,
              ease: 'power2.out',
            })
          },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  10. ClosingCTA                                                     */
/* ------------------------------------------------------------------ */
export function useClosingAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        const tl = gsap.timeline({
          scrollTrigger: { trigger: containerRef.current, start: 'top 75%', once: true },
        })

        const split = SplitText.create('.closing-h2', { type: 'words' })
        tl.from(split.words, {
          y: 50,
          autoAlpha: 0,
          rotateX: 20,
          stagger: 0.05,
          duration: 0.9,
          ease: 'power3.out',
        })

        tl.from('.closing-p', { y: 20, autoAlpha: 0, duration: 0.6 }, '-=0.5')

        tl.from(
          '.closing-cta a',
          { scale: 0.9, autoAlpha: 0, stagger: 0.1, duration: 0.6, ease: 'back.out(1.7)' },
          '-=0.3'
        )
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

/* ------------------------------------------------------------------ */
/*  11. Footer                                                         */
/* ------------------------------------------------------------------ */
export function useFooterAnimation() {
  const containerRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      const ctx = gsap.context(() => {
        gsap.from('.foot-inner', {
          y: 15,
          autoAlpha: 0,
          duration: 0.6,
          ease: 'power2.out',
          scrollTrigger: { trigger: containerRef.current, start: 'top 90%', once: true },
        })
      }, containerRef)

      return () => ctx.revert()
    },
    { scope: containerRef }
  )

  return containerRef
}

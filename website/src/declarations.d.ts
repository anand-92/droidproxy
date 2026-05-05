declare module '@andresclua/infinite-marquee-gsap' {
  import { TimelineLite, TimelineMax } from 'gsap/gsap-core'
  export function horizontalLoop(
    items: Element[] | NodeList | string,
    config?: Record<string, unknown>
  ): gsap.core.Timeline
  export function verticalLoop(
    items: Element[] | NodeList | string,
    config?: Record<string, unknown>
  ): gsap.core.Timeline
}

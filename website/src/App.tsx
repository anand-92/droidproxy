import { useGSAP } from '@gsap/react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { SplitText } from 'gsap/SplitText'

import Navbar from './components/Navbar'
import HeroSection from './components/HeroSection'
import LogosStrip from './components/LogosStrip'
import UseCasesSection from './components/UseCasesSection'
import HowItWorksSection from './components/HowItWorksSection'
import ModelsSection from './components/ModelsSection'
import MaxModeSection from './components/MaxModeSection'
import InstallSection from './components/InstallSection'
import SpecsSection from './components/SpecsSection'
import ClosingCTA from './components/ClosingCTA'
import Footer from './components/Footer'

gsap.registerPlugin(useGSAP, ScrollTrigger, SplitText)

function App() {
  return (
    <>
      <Navbar />
      <main>
        <HeroSection />
        <LogosStrip />
        <UseCasesSection />
        <HowItWorksSection />
        <ModelsSection />
        <MaxModeSection />
        <InstallSection />
        <SpecsSection />
        <ClosingCTA />
      </main>
      <Footer />
    </>
  )
}

export default App

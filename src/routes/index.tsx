import { createFileRoute } from "@tanstack/react-router";
import { ArrowDown, ArrowUpRight, Code2, Github, Globe, Mail, Menu, Sparkles, X } from "lucide-react";
import { useState } from "react";

export const Route = createFileRoute("/")({ component: Portfolio });

const projects = [
  { title: "Experiências Web 3D", description: "Projetos interativos para navegador com ambientes 3D, interfaces modernas e foco em jogabilidade.", tags: ["HTML", "JavaScript", "Three.js"], number: "01" },
  { title: "Games & Protótipos", description: "Conceitos de jogos com sistemas próprios, animações, menus e experiências pensadas para serem jogadas.", tags: ["Game Dev", "Web", "UI/UX"], number: "02" },
  { title: "Interfaces Digitais", description: "Sites e aplicações com visual marcante, responsividade e componentes construídos para uma boa experiência.", tags: ["React", "TypeScript", "Design"], number: "03" },
];

function Portfolio() {
  const [menuOpen, setMenuOpen] = useState(false);
  const closeMenu = () => setMenuOpen(false);

  return (
    <main className="min-h-screen overflow-hidden bg-[#08090b] text-white selection:bg-white selection:text-black">
      <div className="pointer-events-none fixed inset-0 -z-0 bg-[radial-gradient(circle_at_75%_10%,rgba(255,255,255,0.09),transparent_28%),radial-gradient(circle_at_10%_65%,rgba(120,120,120,0.08),transparent_25%)]" />
      <header className="fixed left-0 right-0 top-0 z-50 border-b border-white/10 bg-[#08090b]/75 backdrop-blur-xl">
        <div className="mx-auto flex h-20 max-w-7xl items-center justify-between px-6 lg:px-10">
          <a href="#inicio" onClick={closeMenu} className="text-lg font-bold tracking-[-0.04em]">VF<span className="text-white/35">.</span></a>
          <nav className="hidden items-center gap-8 text-sm text-white/55 md:flex">
            <a className="transition hover:text-white" href="#inicio">Início</a><a className="transition hover:text-white" href="#sobre">Sobre</a><a className="transition hover:text-white" href="#projetos">Projetos</a><a className="transition hover:text-white" href="#contato">Contato</a>
          </nav>
          <a href="#contato" className="hidden rounded-full border border-white/15 px-5 py-2.5 text-sm font-medium transition hover:border-white/40 hover:bg-white hover:text-black md:block">Vamos conversar</a>
          <button aria-label="Abrir menu" onClick={() => setMenuOpen(!menuOpen)} className="rounded-full border border-white/10 p-2 md:hidden">{menuOpen ? <X size={20} /> : <Menu size={20} />}</button>
        </div>
        {menuOpen && <nav className="border-t border-white/10 bg-[#08090b] px-6 py-5 md:hidden">{[["Início","#inicio"],["Sobre","#sobre"],["Projetos","#projetos"],["Contato","#contato"]].map(([label, href]) => <a key={href} href={href} onClick={closeMenu} className="block py-3 text-white/70">{label}</a>)}</nav>}
      </header>

      <section id="inicio" className="relative mx-auto flex min-h-screen max-w-7xl items-center px-6 pb-20 pt-32 lg:px-10">
        <div className="grid w-full gap-14 lg:grid-cols-[1.15fr_0.85fr] lg:items-center">
          <div>
            <div className="mb-7 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-4 py-2 text-xs text-white/55"><Sparkles size={14} />Portfólio pessoal · Desenvolvedor & Criador</div>
            <h1 className="max-w-4xl text-6xl font-semibold leading-[0.92] tracking-[-0.07em] sm:text-7xl lg:text-[clamp(5rem,9vw,8.5rem)]">Ideias que<span className="block text-white/35">viram projetos.</span></h1>
            <p className="mt-8 max-w-xl text-base leading-7 text-white/50 sm:text-lg">Sou um criador apaixonado por tecnologia, desenvolvimento de jogos e experiências digitais. Aqui estão alguns dos projetos que representam o que eu gosto de construir.</p>
            <div className="mt-10 flex flex-wrap gap-3">
              <a href="#projetos" className="group inline-flex items-center gap-2 rounded-full bg-white px-6 py-3.5 text-sm font-semibold text-black transition hover:scale-[1.02]">Ver projetos<ArrowDown size={16} className="transition group-hover:translate-y-0.5" /></a>
              <a href="#contato" className="inline-flex items-center gap-2 rounded-full border border-white/15 px-6 py-3.5 text-sm font-semibold text-white transition hover:border-white/40 hover:bg-white/5">Entrar em contato<ArrowUpRight size={16} /></a>
            </div>
          </div>
          <div className="relative mx-auto w-full max-w-md">
            <div className="aspect-square rounded-[2rem] border border-white/10 bg-gradient-to-br from-white/[0.1] via-white/[0.02] to-transparent p-px">
              <div className="flex h-full flex-col justify-between rounded-[2rem] bg-[#0d0f12] p-7">
                <div className="flex items-center justify-between text-xs text-white/35"><span>PORTFOLIO / 2026</span><span>01—03</span></div>
                <div><Code2 size={42} strokeWidth={1.2} className="mb-8 text-white/70" /><div className="text-3xl font-semibold tracking-[-0.05em]">Criar.<br />Experimentar.<br />Evoluir.</div></div>
                <div className="h-px w-full bg-white/10" />
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="sobre" className="border-y border-white/10 bg-white/[0.025]">
        <div className="mx-auto grid max-w-7xl gap-10 px-6 py-24 lg:grid-cols-[0.7fr_1.3fr] lg:px-10">
          <div><p className="text-xs font-semibold uppercase tracking-[0.25em] text-white/35">Sobre mim</p><h2 className="mt-4 text-4xl font-semibold tracking-[-0.05em] sm:text-5xl">Construindo na prática.</h2></div>
          <div className="max-w-2xl text-lg leading-8 text-white/50"><p>Gosto de transformar ideias em coisas que podem ser usadas, jogadas e exploradas. Meu foco passa por desenvolvimento web, jogos, interfaces e experimentação com tecnologias diferentes.</p><div className="mt-8 flex flex-wrap gap-2">{["React","TypeScript","JavaScript","HTML/CSS","Game Dev","UI/UX"].map((item) => <span key={item} className="rounded-full border border-white/10 px-4 py-2 text-sm text-white/60">{item}</span>)}</div></div>
        </div>
      </section>

      <section id="projetos" className="mx-auto max-w-7xl px-6 py-28 lg:px-10">
        <div className="mb-14 flex items-end justify-between gap-6"><div><p className="text-xs font-semibold uppercase tracking-[0.25em] text-white/35">Projetos selecionados</p><h2 className="mt-4 text-4xl font-semibold tracking-[-0.05em] sm:text-6xl">O que eu construo.</h2></div><span className="hidden text-sm text-white/30 sm:block">2026 / Portfolio</span></div>
        <div className="grid gap-5 lg:grid-cols-3">{projects.map((project) => <article key={project.number} className="group relative min-h-[430px] overflow-hidden rounded-[1.75rem] border border-white/10 bg-[#0d0f12] p-7 transition duration-300 hover:-translate-y-1 hover:border-white/25"><div className="absolute right-7 top-7 text-xs text-white/25">{project.number}</div><div className="flex h-full flex-col justify-between"><div><div className="mb-20 flex h-14 w-14 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04]">{project.number === "01" ? <Globe size={23} /> : project.number === "02" ? <Code2 size={23} /> : <Sparkles size={23} />}</div><h3 className="text-2xl font-semibold tracking-[-0.04em]">{project.title}</h3><p className="mt-4 leading-7 text-white/45">{project.description}</p></div><div className="mt-8 flex flex-wrap gap-2">{project.tags.map((tag) => <span key={tag} className="rounded-full bg-white/[0.05] px-3 py-1.5 text-xs text-white/45">{tag}</span>)}</div></div></article>)}</div>
      </section>

      <section id="contato" className="border-t border-white/10">
        <div className="mx-auto max-w-7xl px-6 py-28 lg:px-10"><p className="text-xs font-semibold uppercase tracking-[0.25em] text-white/35">Contato</p><div className="mt-5 flex flex-col justify-between gap-10 lg:flex-row lg:items-end"><h2 className="max-w-3xl text-5xl font-semibold leading-[0.95] tracking-[-0.06em] sm:text-7xl">Tem uma ideia?<span className="block text-white/35">Vamos construir.</span></h2><div className="flex flex-col gap-3"><a href="mailto:seuemail@email.com" className="inline-flex items-center gap-3 rounded-full bg-white px-6 py-4 text-sm font-semibold text-black transition hover:scale-[1.02]"><Mail size={17} />seuemail@email.com</a><a href="https://github.com/vfeitosades-dot" target="_blank" rel="noreferrer" className="inline-flex items-center gap-3 rounded-full border border-white/15 px-6 py-4 text-sm font-semibold transition hover:border-white/40"><Github size={17} />GitHub</a></div></div></div>
      </section>

      <footer className="border-t border-white/10 px-6 py-7 lg:px-10"><div className="mx-auto flex max-w-7xl flex-col justify-between gap-3 text-xs text-white/30 sm:flex-row"><span>© 2026 · Seu portfólio</span><span>Feito com código e criatividade.</span></div></footer>
    </main>
  );
}

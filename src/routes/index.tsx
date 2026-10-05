import { createFileRoute } from "@tanstack/react-router";
import {
  ArrowDownRight,
  ArrowUpRight,
  Code2,
  Github,
  Globe2,
  Layers3,
  Mail,
  Menu,
  Sparkles,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/")({ component: Portfolio });

const projects = [
  { index: "01", title: "Experiências Web 3D", description: "Interfaces e experiências interativas para navegador, combinando movimento, profundidade e tecnologia.", tags: ["Web", "3D", "JavaScript"], icon: Globe2 },
  { index: "02", title: "Games & Protótipos", description: "Projetos de jogos com sistemas próprios, animações, menus e foco em sensação de controle e diversão.", tags: ["Game Dev", "Physics", "UI"], icon: Layers3 },
  { index: "03", title: "Produtos Digitais", description: "Sites e aplicações responsivas com identidade visual forte, componentes reutilizáveis e experiências fluidas.", tags: ["React", "TypeScript", "Design"], icon: Code2 },
];

function Portfolio() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrollY, setScrollY] = useState(0);
  const [mouse, setMouse] = useState({ x: 0, y: 0 });

  useEffect(() => {
    let frame = 0;
    const onScroll = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => setScrollY(window.scrollY));
    };
    const onMouseMove = (event: MouseEvent) => {
      setMouse({
        x: (event.clientX / window.innerWidth - 0.5) * 2,
        y: (event.clientY / window.innerHeight - 0.5) * 2,
      });
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("mousemove", onMouseMove, { passive: true });

    const revealItems = document.querySelectorAll<HTMLElement>(".reveal-on-view");
    const revealObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            revealObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.16, rootMargin: "0px 0px -8% 0px" },
    );

    revealItems.forEach((item, index) => {
      item.style.transitionDelay = Math.min(index * 70, 280) + "ms";
      revealObserver.observe(item);
    });

    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("mousemove", onMouseMove);
      revealObserver.disconnect();
    };
  }, []);

  const heroProgress = Math.min(scrollY / 620, 1);
  const presentationProgress = Math.min(Math.max((scrollY - 80) / 430, 0), 1);
  const closeMenu = () => setMenuOpen(false);

  return (
    <main className="portfolio-page min-h-screen overflow-x-hidden bg-[#07080a] text-white">
      <div className="portfolio-noise" aria-hidden="true" />
      <div
        className="portfolio-grid"
        aria-hidden="true"
        style={{
          transform: "translate3d(0, " + scrollY * 0.12 + "px, 0)",
          opacity: Math.max(0.2, 1 - scrollY / 1500),
        }}
      />
      <div className="portfolio-progress"><div style={{ transform: "scaleX(" + Math.min(scrollY / 2800, 1) + ")" }} /></div>

      <header className="portfolio-header">
        <div className="mx-auto flex h-[78px] max-w-7xl items-center justify-between px-6 lg:px-10">
          <a href="#top" onClick={closeMenu} className="portfolio-logo">VF<span>.</span></a>
          <nav className="portfolio-nav">
            <a href="#top">Início</a><a href="#sobre">Sobre</a><a href="#projetos">Projetos</a><a href="#contato">Contato</a>
          </nav>
          <a className="portfolio-nav-cta" href="#contato">Vamos conversar <ArrowUpRight size={15} /></a>
          <button aria-label="Abrir menu" onClick={() => setMenuOpen((value) => !value)} className="portfolio-menu-button">{menuOpen ? <X size={20} /> : <Menu size={20} />}</button>
        </div>
        {menuOpen && <nav className="portfolio-mobile-nav">
          <a href="#top" onClick={closeMenu}>Início</a><a href="#sobre" onClick={closeMenu}>Sobre</a><a href="#projetos" onClick={closeMenu}>Projetos</a><a href="#contato" onClick={closeMenu}>Contato</a>
        </nav>}
      </header>

      <section id="top" className="portfolio-hero">
        <div
          className="portfolio-hero-copy"
          style={{
            transform: "translate3d(0, " + scrollY * -0.12 + "px, 0)",
            opacity: Math.max(0, 1 - heroProgress * 1.15),
            filter: "blur(" + heroProgress * 4 + "px)",
          }}
        >
          <div className="portfolio-eyebrow"><span className="portfolio-live-dot" />PORTFÓLIO 2026</div>
          <p className="portfolio-kicker">Olá, eu sou Vinícius.</p>
          <h1>Eu transformo<span>ideias em</span><em>experiências.</em></h1>
          <p className="portfolio-hero-description">Desenvolvedor e criador de projetos digitais, com foco em web, games e experiências interativas que têm personalidade.</p>
          <div
            className="portfolio-intro-reveal"
            style={{
              opacity: presentationProgress,
              transform: "translate3d(0, " + (1 - presentationProgress) * 28 + "px, 0)",
            }}
          >
            <span>UMA BREVE APRESENTAÇÃO</span>
            <strong>Eu sou Vinícius — gosto de transformar código em experiências que parecem vivas.</strong>
          </div>
          <div className="portfolio-hero-actions">
            <a href="#projetos" className="portfolio-primary-btn">Explorar projetos <ArrowUpRight size={17} /></a>
            <a href="#sobre" className="portfolio-secondary-btn">Conhecer meu trabalho</a>
          </div>
        </div>

        <div className="portfolio-scene" aria-hidden="true">
          <div
            className="scene-photo"
            style={{
              transform: "translate3d(" + mouse.x * 15 + "px, " + (mouse.y * 12 + scrollY * -0.14) + "px, 0) rotateX(" + mouse.y * -3 + "deg) rotateY(" + mouse.x * 5 + "deg)",
            }}
          >
            <div className="scene-photo-shine" />
            <span>ABSTRACT / 3D</span>
          </div>
          <div className="scene-halo" style={{ transform: "translate3d(" + mouse.x * 22 + "px, " + (mouse.y * 18 + scrollY * -0.08) + "px, 0)" }} />
          <div
            className="scene-orb"
            style={{
              transform: "translate3d(" + mouse.x * 28 + "px, " + (mouse.y * 20 + scrollY * -0.18) + "px, 0) rotateX(" + mouse.y * -10 + "deg) rotateY(" + mouse.x * 12 + "deg)",
            }}
          >
            <div className="scene-orb-shine" />
          </div>
          <div
            className="scene-ring scene-ring-a"
            style={{
              transform: "translate3d(" + mouse.x * -20 + "px, " + (mouse.y * -15 + scrollY * 0.08) + "px, 0) rotateX(67deg) rotateZ(" + scrollY * 0.05 + "deg)",
            }}
          />
          <div
            className="scene-ring scene-ring-b"
            style={{
              transform: "translate3d(" + mouse.x * -12 + "px, " + (mouse.y * -10 + scrollY * -0.12) + "px, 0) rotateY(68deg) rotateZ(" + scrollY * -0.04 + "deg)",
            }}
          />
          <div
            className="scene-cube"
            style={{
              transform: "translate3d(" + mouse.x * -35 + "px, " + (mouse.y * -24 + scrollY * -0.22) + "px, 0) rotateX(" + (45 + scrollY * 0.08) + "deg) rotateY(" + (55 + scrollY * -0.08) + "deg)",
            }}
          >
            <span /><span /><span /><span /><span /><span />
          </div>
          <div className="scene-mini-card"><span>BUILD / CREATE</span><strong>01—03</strong></div>
          <div className="scene-data"><span>01</span><i /><span>SCROLL / EXPLORE</span></div>
        </div>

        <div className="portfolio-scroll-hint" style={{ opacity: Math.max(0, 1 - heroProgress * 2.2) }}>
          <span>ROLE PARA EXPLORAR</span><ArrowDownRight size={16} />
        </div>
      </section>

      <section id="sobre" className="portfolio-section portfolio-about">
        <div className="portfolio-section-label">01 / Sobre</div>
        <div className="portfolio-about-content">
          <p className="portfolio-big-copy reveal-on-view">Não quero apenas fazer algo que funciona.<span>Quero criar algo que você lembra.</span></p>
          <div className="portfolio-about-grid reveal-on-view">
            <p>Meu trabalho mistura código, design, interação e experimentação. Gosto de pegar uma ideia simples e transformá-la em algo com identidade própria, seja um site, um jogo ou um protótipo.</p>
            <div className="portfolio-stack">{["React", "TypeScript", "JavaScript", "HTML / CSS", "Game Dev", "3D Web"].map((item) => <span key={item}>{item}</span>)}</div>
          </div>
        </div>
      </section>

      <section id="projetos" className="portfolio-section">
        <div className="portfolio-project-header">
          <div><div className="portfolio-section-label">02 / Projetos</div><h2 className="portfolio-title reveal-on-view">Coisas que<span>saíram da tela.</span></h2></div>
          <p>Seleção de experiências e conceitos.</p>
        </div>
        <div className="portfolio-projects">
          {projects.map((project) => {
            const Icon = project.icon;
            return <article key={project.index} className="project-card reveal-on-view">
              <div className="project-card-top"><span>{project.index}</span><ArrowUpRight className="project-arrow" size={22} /></div>
              <div className="project-card-art"><div className="project-card-orb" /><Icon className="project-card-icon" size={50} strokeWidth={1.1} /></div>
              <div><h3>{project.title}</h3><p>{project.description}</p><div className="project-tags">{project.tags.map((tag) => <span key={tag}>{tag}</span>)}</div></div>
            </article>;
          })}
        </div>
      </section>

      <section className="portfolio-marquee" aria-hidden="true">
        <div>CRIAR <span>×</span> EXPERIMENTAR <span>×</span> EVOLUIR <span>×</span> CRIAR <span>×</span> EXPERIMENTAR <span>×</span></div>
      </section>

      <section id="contato" className="portfolio-contact">
        <div className="contact-orbit orbit-one" /><div className="contact-orbit orbit-two" />
        <div className="portfolio-section-label">03 / Contato</div>
        <h2 className="reveal-on-view">Vamos criar<span>algo fora do comum.</span></h2>
        <p className="reveal-on-view">Um projeto, um jogo, um site ou aquela ideia que ainda está no papel.</p>
        <div className="portfolio-contact-actions reveal-on-view">
          <a href="mailto:seuemail@email.com" className="portfolio-primary-btn"><Mail size={17} /> seuemail@email.com</a>
          <a href="https://github.com/vfeitosades-dot" target="_blank" rel="noreferrer" className="portfolio-secondary-btn"><Github size={17} /> GitHub</a>
        </div>
      </section>

      <footer className="portfolio-footer"><span>VF. / PORTFÓLIO</span><span>Feito com código, curiosidade e criatividade.</span></footer>
    </main>
  );
}

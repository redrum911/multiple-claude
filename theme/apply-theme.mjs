import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const HERE = new URL('.', import.meta.url).pathname
const SLOT = ['extensions', 'fmkadmapgofadopljbjfkapdkoienihi']
const LOOK = { motion: 'grid', speed: 4, cell: 14, veil: 0.4 }
const THEMES = JSON.parse(readFileSync(join(HERE, 'themes.json'), 'utf8'))

const [dataDir, id] = process.argv.slice(2)
if (!dataDir || !id) {
  console.error(`usage: node apply-theme.mjs <user-data-dir> <theme|none>\nthemes: ${Object.keys(THEMES).join(', ')}`)
  process.exit(2)
}

const dir = join(dataDir, ...SLOT)
if (id === 'none') {
  if (existsSync(dir)) rmSync(dir, { recursive: true })
  console.log(`theme removed: ${dataDir}`)
  process.exit(0)
}

const t = THEMES[id]
if (!t) {
  console.error(`unknown theme "${id}". themes: ${Object.keys(THEMES).join(', ')}`)
  process.exit(2)
}

const css = name => {
  const f = join(HERE, 'css', `${name}.css`)
  return existsSync(f) ? readFileSync(f, 'utf8') : ''
}

const stars = () => {
  const TILE = [960, 720], COUNT = 46, SPARKLE = 0.35, BASE = [0.25, 0.55], PERIOD = [6, 16]
  const COLORS = ['#dce6fa', '#dce6fa', '#9cc8ff', '#ffffff']
  let s = 7
  const rnd = () => (s = (s * 1103515245 + 12345) % 2147483648) / 2147483648
  const pick = ([a, b]) => a + (b - a) * rnd()
  const f = n => +n.toFixed(2)
  const kt = '0;0.45;0.5;0.55;1'
  const out = []
  for (let i = 0; i < COUNT; i++) {
    const x = f(pick([6, TILE[0] - 6])), y = f(pick([6, TILE[1] - 6]))
    const r = f(pick([0.5, 1.1])), c = COLORS[Math.floor(rnd() * COLORS.length)]
    const base = f(pick(BASE)), dur = f(pick(PERIOD)), begin = f(pick([0, dur]))
    const anim = (attr, v) =>
      `<animate attributeName='${attr}' values='${v}' keyTimes='${kt}' dur='${dur}s' begin='${begin}s' repeatCount='indefinite'/>`
    let g = `<circle cx='${x}' cy='${y}' r='${r}' fill='${c}' opacity='${base}'>`
      + anim('opacity', `${base};${base};1;${base};${base}`) + anim('r', `${r};${r};${f(r * 1.9)};${r};${r}`) + '</circle>'
    if (rnd() < SPARKLE) {
      const k = f(pick([5, 9]))
      const star = `M0 -${k} Q0 0 ${k} 0 Q0 0 0 ${k} Q0 0 -${k} 0 Q0 0 0 -${k}Z`
      g += `<g transform='translate(${x} ${y})'><g transform='scale(0)'>`
        + `<animateTransform attributeName='transform' type='scale' values='0;0;1;0;0' keyTimes='${kt}' dur='${dur}s' begin='${begin}s' repeatCount='indefinite'/>`
        + `<circle r='${f(k * 0.55)}' fill='${c}' opacity='.18'/><path d='${star}' fill='${c}'/></g></g>`
    }
    out.push(g)
  }
  const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='${TILE[0]}' height='${TILE[1]}'>${out.join('')}</svg>`
  return { url: `data:image/svg+xml;utf8,${svg.replace(/#/g, '%23')}`, tile: `${TILE[0]}px ${TILE[1]}px` }
}

let body = [css('_base'), t.wallpaper ? css('_wallpaper') : '', css(id)].join('\n')
if (body.includes('__STARS__')) {
  const { url, tile } = stars()
  body = body.replaceAll('__STARS__', url).replaceAll('__TILE__', tile)
}
if (/\\|@import/.test(body) || /url\(\s*(?!['"]?data:)/i.test(body)) throw new Error('CSS would be rejected by the extension')

mkdirSync(dir, { recursive: true })
for (const f of ['manifest.json', 'theme.js']) copyFileSync(join(HERE, 'extension', f), join(dir, f))
if (!existsSync(join(dir, 'event.json'))) writeFileSync(join(dir, 'event.json'), '{}')
const { name, ...colors } = t
writeFileSync(join(dir, 'theme.json'), JSON.stringify({ id, ...colors, ...LOOK, css: body }))
console.log(`theme ${id} -> ${dir}`)

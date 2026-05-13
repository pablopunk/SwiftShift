import fs from "node:fs"
import type { Config } from "tailwindcss"
import defaultTheme from "tailwindcss/defaultTheme"

const layout = fs.readFileSync("./src/layouts/Layout.astro", "utf8")
const accent1 = layout.match(/--accent-1: var\(--(.+?)-1\);/)?.[1]
const accent2 = layout.match(/--accent2-1: var\(--(.+?)-1\);/)?.[1]
const neutral = layout.match(/--neutral-1: var\(--(.+?)-1\);/)?.[1]

if (!accent1 || !accent2 || !neutral) {
	throw new Error("Could not find accent or neutral color names in Layout.astro")
}

function getColorScale(name: string) {
	const scale = {} as Record<string, string>

	for (let i = 1; i <= 12; i++) {
		scale[i] = `var(--${name}-${i})`
		// next line only needed if using alpha values
		// scale[`a${i}`] = `var(--${name}-a${i})`
	}

	return scale
}

const config: Config = {
	content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
	darkMode: "class",
	theme: {
		extend: {
			colors: {
				accent: getColorScale(accent1),
				accent2: getColorScale(accent2),
				neutral: getColorScale(neutral),
			},
			fontFamily: {
				sans: ["Lexend Variable", ...defaultTheme.fontFamily.sans],
				rubik: ["Rubik Variable", ...defaultTheme.fontFamily.sans],
				serif: ["Literata Variable", ...defaultTheme.fontFamily.serif],
			},
		},
	},
	plugins: [],
}

export default config

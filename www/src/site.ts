export const mainUrl = "https://swiftshift.app"

const processEnv = import.meta.env
const vercelUrl = processEnv.NEXT_PUBLIC_VERCEL_URL
const url = processEnv.DEV
  ? "http://localhost:4321"
  : `https://${vercelUrl || mainUrl.replace("https://", "")}`

const site = {
  SITE_URL: url,
  SITE_NAME: "Swift Shift | Manage your mac's windows like a pro",
  SITE_DESC:
    "Swift Shift lets you move/resize windows with your mouse without searching for tiny arrows or window titles. It's the fastest way to organize your workspace to your liking.",
  SITE_IMAGE: `${url}/header-light-extended.png`,
  SITE_COPYRIGHT: "Pablo Varela",
  SITE_REPO: "https://github.com/pablopunk/SwiftShift",
  SITE_KEYWORDS: [
    "mac",
    "os",
    "app",
    "macosapp",
    "window",
    "manager",
    "swift",
    "shift",
    "shortcut",
    "move",
    "resize",
    "keyboard",
    "productivity",
    "workspace",
    "organize",
    "efficient",
    "fast",
    "easy",
    "free",
    "open",
    "source",
    "pablopunk",
    "pablovarela",
    "swiftshift",
  ],
}

export default site

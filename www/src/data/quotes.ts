export interface Quote {
  id: string
  text: string
  attribution: string
  platform: "reddit" | "lifehacker" | "twitter" | "appaddict"
  url: string
}

export const quotes: Quote[] = [
  {
    id: "quote-8",
    text: "The window management tool Apple should have built",
    attribution: "LifeHacker Review",
    platform: "lifehacker",
    url: "https://lifehacker.com/tech/swift-shift-is-the-window-management-tool-apple-should-have-built",
  },
  {
    id: "quote-twitter-1",
    text: "When it comes to resizing and moving app windows, macOS still has a long way to go. #SwiftShift offers a buttery-smooth respite to those woes for free.",
    attribution: "Digital Trends",
    platform: "twitter",
    url: "https://x.com/DigitalTrends/status/1918874864234250242",
  },
  {
    id: "quote-twitter-2",
    text: "Just started using SwiftShift...What a FANTASTIC job you did with this app. Such a simple but powerful app and executed perfectly. Thank you! ;-)",
    attribution: "Dean",
    platform: "twitter",
    url: "https://x.com/deanfx/status/1926472726597804362",
  },
  {
    id: "quote-1",
    text: "Simplicity. Freedom. What else? Genius.",
    attribution: "Reddit User",
    platform: "reddit",
    url: "https://reddit.com/r/macapps/comments/1eiyz37/",
  },
  {
    id: "quote-2",
    text: "Wow, it's genuinely brilliant! Clean and simple too, exactly what I was looking for",
    attribution: "Jaiden97",
    platform: "reddit",
    url: "https://reddit.com/r/MacOS/comments/18ujz24/",
  },
  {
    id: "quote-3",
    text: "This utility is awesome. Will likely save me a lot of time!",
    attribution: "Reddit User",
    platform: "reddit",
    url: "https://reddit.com/r/MacOS/comments/18ujz24/",
  },
  {
    id: "quote-4",
    text: "I would definitely pay a few bucks to support development. It's one of those 'install and forget it's not part of the OS' apps—when I get on a machine without it, I miss it.",
    attribution: "Reddit User",
    platform: "reddit",
    url: "https://reddit.com/r/MacOS/comments/18ujz24/",
  },
  {
    id: "quote-5",
    text: "This is pretty great, especially for trackpad users. Thanks!",
    attribution: "blissed_off",
    platform: "reddit",
    url: "https://reddit.com/r/MacOS/comments/18ujz24/",
  },
  {
    id: "quote-6",
    text: "SwiftShift moves and resizes windows way smoother than other tools",
    attribution: "Reddit User",
    platform: "reddit",
    url: "https://reddit.com/r/macapps/comments/1eiyz37/",
  },
  {
    id: "quote-7",
    text: "I love this—well done!",
    attribution: "scottlewis101",
    platform: "reddit",
    url: "https://reddit.com/r/MacOS/comments/18ujz24/",
  },
]

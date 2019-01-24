# free-roam

## Manifesto
The goal with [FreeRoam](https://freeroam.app) is to build an open community and resource app for free roamers.

Sticking with openness, FreeRoam is open source. [free-roam](https://github.com/freeroamapp/free-roam) contains the client-side code, [back-roads](https://github.com/freeroamapp/back-roads) has the backend code, and  [free-roam-assets](https://github.com/freeroamapp/free-roam-assets).

### Backstory
We're a couple who are just starting out on their full-time RVing lifestyle. Austin's parents have done it for several years now, and we decided to follow suit.

### The team
Rachel: design and community
Austin: programming

---

### Getting Started
`npm install`
`npm run dev`


### Commands
##### `npm run dev` - Starts the server, watching files

More to come soonish


### Cleanup
Occassionally run node /usr/lib/node_modules/coffee-unused/index.js --src ./src and clean up unused vars

More for just clean code vs reduced bundle size. As of 1/19 have only done for src/models and it only saved ~120b gzipped

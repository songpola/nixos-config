// .commitlintrc.js
const fs = require("node:fs")
const path = require("node:path")

let packages = fs.readdirSync(path.resolve(__dirname, "systems/x86_64-linux"))

// Ignore default.template.nix
packages = packages.filter((pkg) => pkg != "default.template.nix")

module.exports = {
  prompt: {
    scopes: [...packages],
  },
}

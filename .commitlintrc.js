// .commitlintrc.js
const fs = require("node:fs")
const path = require("node:path")

const systems = fs
  .readdirSync(path.resolve(__dirname, "systems/x86_64-linux"))
  .filter((pkg) => pkg != "default.template.nix") // Ignore default.template.nix
const disko = fs.readdirSync(path.resolve(__dirname, "disko"))

module.exports = {
  prompt: {
    scopes: [...systems, ...disko],
  },
}

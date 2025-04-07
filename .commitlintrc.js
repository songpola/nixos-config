const fs = require("node:fs")
const path = require("node:path")

const systems = fs.readdirSync(path.resolve(__dirname, "systems/x86_64-linux"))

module.exports = {
  prompt: {
    scopes: [...systems, "just", "nushell", "modules"],
  },
}

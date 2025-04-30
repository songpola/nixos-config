import { readdirSync } from "node:fs"
import { resolve } from "node:path"

const systems = readdirSync(resolve("systems/x86_64-linux"))
const modules = readdirSync(resolve("modules/nixos")).map(
  (module) => `modules/${module}`
)

export const prompt = {
  scopes: [...systems, "modules", ...modules],
}

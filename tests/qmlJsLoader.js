const fs = require("node:fs")
const vm = require("node:vm")
const path = require("node:path")

function loadQmlJs(filename, options = {}) {
    const imports = options.imports || {}
    const cache = options.cache || new Map()
    const resolved = path.resolve(filename)
    if (cache.has(resolved))
        return cache.get(resolved)
    const sandbox = Object.assign({}, options.globals || {}, imports)
    cache.set(resolved, sandbox)
    let source = fs.readFileSync(filename, "utf8")
        .replace(/^\s*\.pragma\s+library\s*$/gm, "")

    source = source.replace(
        /^\s*\.import\s+"([^"]+)"\s+as\s+([A-Za-z_$][\w$]*)\s*$/gm,
        (_directive, importPath, alias) => {
            // Resolve the same module graph as QML while preserving explicit
            // test doubles. New internal modules do not require fake imports.
            if (!Object.prototype.hasOwnProperty.call(imports, alias)) {
                sandbox[alias] = loadQmlJs(path.resolve(path.dirname(resolved), importPath), {
                    globals: options.globals,
                    cache
                })
            }
            return ""
        }
    )

    vm.createContext(sandbox)
    vm.runInContext(source, sandbox, { filename })
    return sandbox
}

module.exports = { loadQmlJs }

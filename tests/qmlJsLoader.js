const fs = require("node:fs")
const vm = require("node:vm")

function loadQmlJs(filename, options = {}) {
    const imports = options.imports || {}
    const sandbox = Object.assign({}, options.globals || {}, imports)
    let source = fs.readFileSync(filename, "utf8")
        .replace(/^\s*\.pragma\s+library\s*$/gm, "")

    source = source.replace(
        /^\s*\.import\s+"([^"]+)"\s+as\s+([A-Za-z_$][\w$]*)\s*$/gm,
        (_directive, _importPath, alias) => {
            if (!Object.prototype.hasOwnProperty.call(imports, alias))
                throw new Error(`Missing QML JavaScript import '${alias}' while loading ${filename}`)
            return ""
        }
    )

    vm.createContext(sandbox)
    vm.runInContext(source, sandbox, { filename })
    return sandbox
}

module.exports = { loadQmlJs }

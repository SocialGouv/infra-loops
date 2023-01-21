const fs = require("fs-extra")

const { loaderFactory, yaml } = require("foundernetes")

module.exports = loaderFactory(async () => ({
  // retry: 3,
  load: async (vars) => {
    const { file } = vars
    const content = await fs.readFile(file, { encoding: "utf-8" })
    const data = yaml.loadAll(content)
    return data
  },
  validateVars: {
    type: "object",
    properties: {
      file: { type: "string" },
    },
    required: ["file"],
    additionalProperties: false,
  },
  validateData: {
    type: "array",
    items: {
      type: "object",
      properties: {
        name: { type: "string" },
      },
      required: ["name"],
      additionalProperties: true,
    },
  },
  memoizeVars: ["file"],
}))

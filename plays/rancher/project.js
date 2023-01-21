const { setTimeout: sleep } = require("timers/promises")
const { playFactory, ctx, FoundernetesPlayCheckError } = require("foundernetes")

module.exports = playFactory(async () => ({
  retry: 1,
  // async check() {
  //   return false
  //   // return Math.random() > 0.5
  // },
  async preCheck() {
    throw new FoundernetesPlayCheckError("a stuff is not ready")
    return false
  },
  async postCheck() {
    throw new Error("TEST")
    // return false
  },
  async run(vars, _context) {
    // const { retryNumber } = context
    // console.log("vars", vars)
    const { projectName } = vars
    await sleep(2000)
    const logger = ctx.require("logger")
    logger.info(`creating rancher project: ${projectName}`)
    return true
  },
}))

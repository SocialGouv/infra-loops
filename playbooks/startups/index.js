const { playbookFactory, ctx } = require("foundernetes")

const commonFactory = require("./common")
const loadersFactory = require("./loaders")
const playsFactory = require("./plays")
const iteratorsFactory = require("./iterators")

module.exports = playbookFactory(async () => {
  const common = await commonFactory()
  const loaders = await loadersFactory({ ...common })
  const plays = await playsFactory({ ...common })
  const iterators = await iteratorsFactory({ ...common })

  const playbook = async () => {
    // const logger = ctx.require("logger")

    const startupsList = await loaders.startups({
      file: "inventories/startups.yaml",
    })

    const iterator = ctx.require("iterator")
    await iterator.mapOfSeries(
      startupsList,
      async (startup) => {
        const { name, rancherProjectName = name } = startup
        await plays.rancherProject({
          projectName: rancherProjectName,
        })
        // return false
      },
      "startups-list"
    )

    // await iterator.each(startupsList, async (item, index) => {
    //   console.log({ index, item })
    //   await iterator.eachOf(item, async (val, key) => {
    //     console.log({ index, item, key, val })
    //   })
    // })
  }

  const middlewares = [...common.middlewares]

  return {
    playbook,
    middlewares,
    iterators,
  }
})

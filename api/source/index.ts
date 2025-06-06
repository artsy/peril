import * as cluster from "cluster"
import * as os from "os"

import logger from "./logger"
import { peril } from "./peril"

const WORKERS = process.env.NODE_ENV === "production" ? Number(process.env.WEB_CONCURRENCY) || os.cpus().length : 1
const log = (message: string) => {
  if (WORKERS > 1) {
    logger.info(message)
  }
}

// Use isPrimary for newer Node.js versions, fallback to isMaster for older versions
const isPrimary = (cluster as any).isPrimary !== undefined ? (cluster as any).isPrimary : (cluster as any).isMaster

if (isPrimary) {
  log(`[CLUSTER] Master cluster setting up ${WORKERS} workers...`)
  for (let i = 0; i < WORKERS; i++) {
    (cluster as any).fork() // create a worker
  }

  (cluster as any).on("online", (worker: any) => {
    log(`[CLUSTER] Worker ${worker.process.pid} is online`)
  })

  (cluster as any).on("exit", (worker: any, code: any, signal: any) => {
    log(`[CLUSTER] Worker ${worker.process.pid} died with code: ${code}, and signal: ${signal}`)
    log("[CLUSTER] Starting a new worker")
    // start a new worker when it crashes
    ;(cluster as any).fork()
  })
} else {
  peril()
}

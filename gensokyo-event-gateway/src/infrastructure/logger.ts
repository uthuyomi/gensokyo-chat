export function logInfo(message: string, ...args: unknown[]) {
  console.log(message, ...args);
}

export function logWarn(message: string, ...args: unknown[]) {
  console.warn(message, ...args);
}

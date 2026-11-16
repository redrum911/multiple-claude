import type { Register } from 'claude-code'

const SCRIPT = '.claude/sync-claude-apps.sh'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'sync-apps',
      description: 'Restart Claude and its instances to sync Code sessions between them',
    })

    return next(e)
  })

  on('command.run', { command: 'sync-apps' }, async $ => {
    const home = (await $.env.get('HOME')) ?? ''
    const ran = await $.process
      .run([`${home}/${SCRIPT}`], { timeoutMs: 10_000 })
      .catch(() => undefined)

    return {
      text:
        ran?.exitCode === 0
          ? 'Restarting Claude and its instances to sync sessions…'
          : `Could not start ~/${SCRIPT}.`,
    }
  })
}

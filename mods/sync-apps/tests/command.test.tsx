import { expect, test } from 'claude-code/testing'

test('/sync-apps runs the sync script right away', async ($, on) => {
  const ran: string[][] = []
  on('command.register', () => ({ value: { command: 'sync-apps' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('env.get', () => ({ value: '/home/test' }))
  on('process.run', (_, e) => {
    ran.push([...e.argv])
    return {
      value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false },
    }
  })

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const result = await $.command.run({
    command: 'sync-apps',
    args: '',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: false, columns: 80 },
  })

  expect(ran).toEqual([['/home/test/.claude/sync-claude-apps.sh']])
  expect(result.text).toBe('Restarting Claude and its instances to sync sessions…')
})

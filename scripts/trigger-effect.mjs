import fs from 'node:fs'
import path from 'node:path'

const projectRoot = path.resolve(import.meta.dirname, '..')
const access = JSON.parse(fs.readFileSync(path.join(projectRoot, '.runtime', 'access.json'), 'utf8'))
const effectId = process.argv[2] ?? 'knife'
const url = new URL(access.LocalUrl.replace(/^http/, 'ws') + '/ws')
url.searchParams.set('room', access.RoomCode)
url.searchParams.set('role', 'admin')
url.searchParams.set('name', 'Локальная проверка')

const socket = new WebSocket(url)
const timeout = setTimeout(() => {
  finished = true
  console.error('Тайм-аут: сервер не подтвердил выполнение эффекта.')
  socket.close()
  process.exitCode = 1
}, 8000)

socket.addEventListener('open', () => {
  socket.send(JSON.stringify({ type: 'auth', token: access.AdminToken }))
})

let triggered = false
let finished = false
socket.addEventListener('message', event => {
  const message = JSON.parse(event.data)
  if (message.type === 'snapshot' && !triggered) {
    if (!message.agentConnected) throw new Error('Игровой агент не подключён')
    triggered = true
    socket.send(JSON.stringify({ type: 'trigger', effectId }))
    return
  }
  if (message.type === 'triggerRejected' || message.type === 'error') {
    finished = true
    clearTimeout(timeout)
    console.error(`${message.code}: ${message.message}`)
    socket.close()
    process.exitCode = 1
    return
  }
  if (message.type === 'snapshot') {
    const completedEvent = message.events.find(item =>
      item.actor === 'Локальная проверка' && item.effectId === effectId && item.status !== 'sent')
    if (completedEvent) {
      finished = true
      clearTimeout(timeout)
      console.log(`${completedEvent.status}: ${completedEvent.detail}`)
      socket.close()
    }
  }
})

socket.addEventListener('error', () => {
  if (finished) return
  clearTimeout(timeout)
  console.error('Не удалось подключиться к Chaos Link.')
  process.exitCode = 1
})

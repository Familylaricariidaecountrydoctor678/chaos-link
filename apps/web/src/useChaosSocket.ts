import { useCallback, useEffect, useRef, useState } from 'react'
import type { ConnectionState, Credentials, Snapshot } from './types'

type Notice = { tone: 'error' | 'info'; text: string } | null

export function useChaosSocket(credentials: Credentials | null) {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [connection, setConnection] = useState<ConnectionState>('disconnected')
  const [notice, setNotice] = useState<Notice>(null)
  const [clockOffset, setClockOffset] = useState(0)
  const socketRef = useRef<WebSocket | null>(null)

  useEffect(() => {
    if (!credentials) return
    let retryTimer: number | undefined
    let stopped = false

    const connect = () => {
      if (stopped) return
      setConnection('connecting')
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
      const url = new URL(`${protocol}//${window.location.host}/ws`)
      url.searchParams.set('room', credentials.room.toUpperCase())
      url.searchParams.set('role', credentials.role)
      url.searchParams.set('name', credentials.name)
      const socket = new WebSocket(url)
      socketRef.current = socket

      socket.onopen = () => {
        setConnection('connected')
        setNotice(null)
        socket.send(JSON.stringify({ type: 'auth', token: credentials.token }))
        socket.send(JSON.stringify({ type: 'ping', clientTime: Date.now() }))
      }
      socket.onmessage = (event) => {
        const message = JSON.parse(event.data)
        if (message.type === 'snapshot') {
          setSnapshot(message)
          setClockOffset(message.serverTime - Date.now())
        } else if (message.type === 'pong') {
          const roundTrip = Date.now() - message.clientTime
          setClockOffset(message.serverTime + roundTrip / 2 - Date.now())
        } else if (message.type === 'triggerRejected' || message.type === 'error') {
          setNotice({ tone: 'error', text: message.message })
        }
      }
      socket.onerror = () => setConnection('error')
      socket.onclose = () => {
        setConnection('disconnected')
        if (!stopped) retryTimer = window.setTimeout(connect, 2500)
      }
    }

    connect()
    return () => {
      stopped = true
      window.clearTimeout(retryTimer)
      socketRef.current?.close()
      socketRef.current = null
    }
  }, [credentials])

  const send = useCallback((payload: object) => {
    if (socketRef.current?.readyState !== WebSocket.OPEN) {
      setNotice({ tone: 'error', text: 'Нет соединения с комнатой' })
      return false
    }
    socketRef.current.send(JSON.stringify(payload))
    return true
  }, [])

  const trigger = useCallback((effectId: string) => {
    setNotice(null)
    send({ type: 'trigger', effectId })
  }, [send])

  const setPaused = useCallback((paused: boolean) => {
    setNotice(null)
    send({ type: 'pause', paused })
  }, [send])

  const blockUser = useCallback((targetClientId: string) => {
    setNotice(null)
    send({ type: 'blockUser', targetClientId })
  }, [send])

  const setCooldown = useCallback((effectId: string, cooldownSeconds: number) => {
    setNotice(null)
    send({ type: 'setCooldown', effectId, cooldownSeconds })
  }, [send])

  return { snapshot, connection, notice, clockOffset, trigger, setPaused, blockUser, setCooldown }
}

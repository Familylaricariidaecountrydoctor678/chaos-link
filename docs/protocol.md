# WebSocket protocol

Clients connect to:

```text
/ws?room=K7M2&role=controller&name=Egor
/ws?room=K7M2&role=agent&name=Gaming-PC
```

The first message must arrive within five seconds and authenticates the socket
without putting a secret in reverse-proxy access logs:

```json
{ "type": "auth", "token": "friend-access" }
```

Controller messages:

```json
{ "type": "trigger", "effectId": "reload" }
{ "type": "ping", "clientTime": 1785935600000 }
```

Administrator messages:

```json
{ "type": "pause", "paused": true }
{ "type": "blockUser", "targetClientId": "..." }
{ "type": "setCooldown", "effectId": "reload", "cooldownSeconds": 15 }
```

Agent messages:

```json
{ "type": "ack", "eventId": "...", "status": "executed", "detail": null }
{ "type": "ping", "clientTime": 1785935600000 }
```

Every accepted trigger is stamped with a unique `eventId`, one server-owned
`nextAvailableAt`, and one `executeAt`. The room mutation is protected by a
lock, so two simultaneous controller requests cannot both consume an effect.
User blocks last 30 seconds and cooldown changes accept values from 0 to 3600
seconds.

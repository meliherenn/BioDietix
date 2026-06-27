import asyncio
import time
from collections import defaultdict, deque

from fastapi import Depends, HTTPException, Request, status

from utils.api_auth import require_user


class UserRateLimit:
    """Small single-process limiter; use a shared store when running multiple workers."""

    def __init__(self, requests, window_seconds=60):
        self.requests = requests
        self.window_seconds = window_seconds
        self._events = defaultdict(deque)
        self._lock = asyncio.Lock()

    async def __call__(self, request: Request, user=Depends(require_user)):
        uid = str(user.get("uid") or "anonymous")
        key = f"{uid}:{request.url.path}"
        now = time.monotonic()
        cutoff = now - self.window_seconds
        async with self._lock:
            events = self._events[key]
            while events and events[0] <= cutoff:
                events.popleft()
            if len(events) >= self.requests:
                retry_after = max(1, int(events[0] + self.window_seconds - now))
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests.",
                    headers={"Retry-After": str(retry_after)},
                )
            events.append(now)
        return user

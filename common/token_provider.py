import time
import google.auth
from google.auth.transport.requests import Request
from aiokafka.abc import AbstractTokenProvider


class GcpAccessToken:
    def __init__(self):
        self._creds, _ = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        self._req = Request()
        self._token = None
        self._exp_ts = 0.0

    def get(self) -> str:
        now = time.time()
        if not self._token or now > (self._exp_ts - 60):
            self._creds.refresh(self._req)
            self._token = self._creds.token
            self._exp_ts = (
                self._creds.expiry.timestamp() if self._creds.expiry else now + 3600
            )
        return self._token


class GcpAdcTokenProvider(AbstractTokenProvider):
    """
    Returns Google OAuth access tokens from Application Default Credentials (ADC).
    Works in GKE with Workload Identity (KSA->GSA).
    """

    def __init__(self):
        self._creds, _ = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        self._request = Request()
        self._cached_token = None
        self._cached_expiry_ts = 0.0

    async def token(self) -> str:
        # refresh a bit earlier than expiry
        now = time.time()
        if not self._cached_token or now > (self._cached_expiry_ts - 60):
            if not self._creds.valid:
                self._creds.refresh(self._request)

            self._cached_token = self._creds.token

            # google-auth usually sets expiry
            if self._creds.expiry is not None:
                self._cached_expiry_ts = self._creds.expiry.timestamp()
            else:
                # fallback: assume 1 hour if expiry unknown
                self._cached_expiry_ts = now + 3600

        return self._cached_token

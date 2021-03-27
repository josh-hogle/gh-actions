FROM ghcr.io/josh-hogle/gh-actions:0.9.0

COPY ./entrypoint.ps1 /entrypoint.ps1

ENTRYPOINT [ "pwsh", "-ExecutionPolicy", "Bypass", "-File", "/entrypoint.ps1" ]

# CGEventSupervisor

Originally by [Stephan Casas](https://github.com/stephancasas) — [CGEventSupervisor](https://github.com/stephancasas/CGEventSupervisor)

Vendored into SwiftShift with the following fixes:
- Proper Mach port teardown (run loop source removal + `CFMachPortInvalidate`)
- Re-enable tap on `kCGEventTapDisabledByTimeout` / `kCGEventTapDisabledByUserInput`

MIT License.

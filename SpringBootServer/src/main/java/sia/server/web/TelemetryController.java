package sia.server.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import sia.server.Telemetry;

import java.lang.management.ManagementFactory;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicLong;

@RestController
public class TelemetryController {

    private final AtomicLong requestCount = new AtomicLong();

    @GetMapping(value = "/telemetry", produces = "application/json")
    public Telemetry telemetryData() {
        String timestamp = LocalDateTime.now().toString();
        Runtime runtime = Runtime.getRuntime();
        long uptimeMillis = ManagementFactory.getRuntimeMXBean().getUptime();
        long usedMemoryBytes = runtime.totalMemory() - runtime.freeMemory();
        long maxMemoryBytes = runtime.maxMemory();

        return new Telemetry(timestamp, uptimeMillis, usedMemoryBytes, maxMemoryBytes, requestCount.incrementAndGet());
    }
}

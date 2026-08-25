package sia.server.web;

import io.micrometer.tracing.Span;
import io.micrometer.tracing.TraceContext;
import io.micrometer.tracing.Tracer;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import sia.server.Telemetry;

import java.time.LocalDateTime;

@RestController
public class TelemetryController {

    private final Tracer tracer;

    public TelemetryController(Tracer tracer) {
        this.tracer = tracer;
    }

    @GetMapping(value = "/telemetry", produces = "application/json")
    public Telemetry telemetryData() {
        String timestamp = LocalDateTime.now().toString();

        // Read the current span created by Spring/OTel for this request
        Span currentSpan = tracer.currentSpan();

        String traceId = null;
        String spanId = null;

        if (currentSpan != null) {
            TraceContext ctx = currentSpan.context();
            traceId = ctx.traceId();  // links this request to all its logs/spans in backend
            spanId = ctx.spanId();    // identifies this specific unit of work
        }

        return new Telemetry(timestamp, traceId, spanId);
    }
}

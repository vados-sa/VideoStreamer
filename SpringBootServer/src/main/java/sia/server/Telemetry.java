package sia.server;

import lombok.Data;

@Data
public class Telemetry {
    private String timestamp;
    private String traceId;
    private String spanId;

    public Telemetry(String timestamp, String traceId, String spanId) {
        this.timestamp = timestamp;
        this.traceId = traceId;
        this.spanId = spanId;
    }
}

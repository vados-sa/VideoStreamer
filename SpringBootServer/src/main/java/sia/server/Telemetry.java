package sia.server;

import lombok.Data;

@Data
public class Telemetry {
    private String timestamp;
    private long uptimeMillis;
    private long usedMemoryBytes;
    private long maxMemoryBytes;
    private long requestCount;

    public Telemetry(String timestamp, long uptimeMillis, long usedMemoryBytes, long maxMemoryBytes, long requestCount) {
        this.timestamp = timestamp;
        this.uptimeMillis = uptimeMillis;
        this.usedMemoryBytes = usedMemoryBytes;
        this.maxMemoryBytes = maxMemoryBytes;
        this.requestCount = requestCount;
    }
}

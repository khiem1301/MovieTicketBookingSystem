package utils;

/** FR-13 — Ghế không giữ được (race condition hoặc conflict). */
public class SeatHoldException extends RuntimeException {

    public SeatHoldException(String message) {
        super(message);
    }
}

package model.dto;

import java.sql.Timestamp;

/** FR-44 — Một dòng lịch sử giao dịch điểm tích luỹ. */
public class LoyaltyHistoryItem {
    private final String id;
    private final String bookingId;
    private final String bookingCode;
    private final int pointsDelta;
    private final String transactionType;
    private final String note;
    private final Timestamp createdAt;

    public LoyaltyHistoryItem(String id, String bookingId, String bookingCode,
                              int pointsDelta, String transactionType,
                              String note, Timestamp createdAt) {
        this.id = id;
        this.bookingId = bookingId;
        this.bookingCode = bookingCode;
        this.pointsDelta = pointsDelta;
        this.transactionType = transactionType;
        this.note = note;
        this.createdAt = createdAt;
    }

    public String getId()              { return id; }
    public String getBookingId()       { return bookingId; }
    public String getBookingCode()     { return bookingCode; }
    public int getPointsDelta()        { return pointsDelta; }
    public String getTransactionType() { return transactionType; }
    public String getNote()            { return note; }
    public Timestamp getCreatedAt()    { return createdAt; }

    public boolean isEarn()   { return "EARN".equals(transactionType); }
    public boolean isRedeem() { return "REDEEM".equals(transactionType); }
    public boolean isRefund() { return "REFUND_POINTS".equals(transactionType); }
}

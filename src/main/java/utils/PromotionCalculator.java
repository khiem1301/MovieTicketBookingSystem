package utils;

import model.entity.Promotion;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * FR-22 — Tính giảm giá voucher và tổng thanh toán sau VAT.
 */
public final class PromotionCalculator {

    private PromotionCalculator() {}

    /**
     * Số tiền giảm trên subtotal (chưa VAT). Không kiểm tra min_order — gọi {@link #validateMinOrder} trước.
     */
    public static BigDecimal calculateDiscount(Promotion promotion, BigDecimal subtotal) {
        if (promotion == null || subtotal == null || subtotal.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal discount;
        if ("PERCENTAGE".equals(promotion.getDiscountType())) {
            BigDecimal value = promotion.getDiscountValue() != null
                    ? promotion.getDiscountValue() : BigDecimal.ZERO;
            discount = subtotal.multiply(value)
                    .divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP);
            if (promotion.getMaxDiscountAmount() != null
                    && discount.compareTo(promotion.getMaxDiscountAmount()) > 0) {
                discount = promotion.getMaxDiscountAmount();
            }
        } else if ("FIXED_AMOUNT".equals(promotion.getDiscountType())) {
            discount = promotion.getDiscountValue() != null
                    ? promotion.getDiscountValue() : BigDecimal.ZERO;
        } else {
            return BigDecimal.ZERO;
        }

        if (discount.compareTo(subtotal) > 0) {
            discount = subtotal;
        }
        return discount.setScale(0, RoundingMode.HALF_UP);
    }

    /** final = (subtotal - discount) × (1 + vat/100) */
    public static BigDecimal recalculateFinalAmount(BigDecimal subtotal, BigDecimal discount, BigDecimal vatRate) {
        BigDecimal afterDiscount = subtotalAfterDiscount(subtotal, discount);
        BigDecimal rate = vatRate != null ? vatRate : BigDecimal.ZERO;
        return afterDiscount.multiply(
                BigDecimal.ONE.add(rate.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)))
                .setScale(0, RoundingMode.HALF_UP);
    }

    /** VAT trên phần subtotal sau giảm giá. */
    public static BigDecimal calculateVatAmount(BigDecimal subtotal, BigDecimal discount, BigDecimal vatRate) {
        BigDecimal afterDiscount = subtotalAfterDiscount(subtotal, discount);
        BigDecimal rate = vatRate != null ? vatRate : BigDecimal.ZERO;
        return afterDiscount.multiply(rate.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP))
                .setScale(0, RoundingMode.HALF_UP);
    }

    /**
     * @return null nếu hợp lệ; message tiếng Việt nếu không đạt min_order_amount
     */
    public static String validateMinOrder(Promotion promotion, BigDecimal subtotal) {
        if (promotion == null || promotion.getMinOrderAmount() == null) {
            return null;
        }
        BigDecimal sub = subtotal != null ? subtotal : BigDecimal.ZERO;
        if (sub.compareTo(promotion.getMinOrderAmount()) < 0) {
            return "Đơn tối thiểu "
                    + formatVnd(promotion.getMinOrderAmount())
                    + " để dùng mã này.";
        }
        return null;
    }

    private static BigDecimal subtotalAfterDiscount(BigDecimal subtotal, BigDecimal discount) {
        BigDecimal sub = subtotal != null ? subtotal : BigDecimal.ZERO;
        BigDecimal disc = discount != null ? discount : BigDecimal.ZERO;
        BigDecimal after = sub.subtract(disc);
        return after.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : after;
    }

    private static String formatVnd(BigDecimal amount) {
        return String.format("%,.0f", amount);
    }
}

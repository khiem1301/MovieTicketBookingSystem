package util;

import model.entity.Seat;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;

/**
 * Parse / build JSON layout ghế giữa editor frontend và bảng Seats.
 */
public final class SeatLayoutJsonUtil {

    private SeatLayoutJsonUtil() {}

    public static String buildLayoutJson(List<Seat> seats) {
        JSONObject root = new JSONObject();
        JSONArray rowsArr = new JSONArray();

        Map<String, List<Seat>> byRow = new LinkedHashMap<>();
        for (Seat s : seats) {
            byRow.computeIfAbsent(s.getSeatRow(), k -> new ArrayList<>()).add(s);
        }

        for (Map.Entry<String, List<Seat>> entry : byRow.entrySet()) {
            JSONObject rowObj = new JSONObject();
            rowObj.put("label", entry.getKey());
            JSONArray cells = new JSONArray();
            entry.getValue().stream()
                    .sorted(Comparator.comparingInt(Seat::getSeatColumn))
                    .forEach(seat -> {
                        JSONObject cell = new JSONObject();
                        cell.put("kind", "seat");
                        cell.put("type", normalizeTypeName(seat.getSeatTypeName()));
                        cell.put("code", seat.getSeatCode());
                        cell.put("col", seat.getSeatColumn());
                        cells.put(cell);
                    });
            rowObj.put("cells", cells);
            rowsArr.put(rowObj);
        }

        root.put("rows", rowsArr);
        return root.toString();
    }

    /**
     * @param layoutJson   JSON từ frontend
     * @param typeKeyToId  map lowercase type key → seat_type_id UUID
     */
    public static List<Seat> parseSeats(String roomId, String layoutJson, Map<String, String> typeKeyToId) {
        JSONObject root;
        try {
            root = new JSONObject(layoutJson);
        } catch (Exception e) {
            throw new IllegalArgumentException("Dữ liệu layout không hợp lệ.");
        }

        JSONArray rowsArr = root.optJSONArray("rows");
        if (rowsArr == null) {
            throw new IllegalArgumentException("Dữ liệu layout không hợp lệ.");
        }

        List<Seat> result = new ArrayList<>();
        Set<String> codes = new HashSet<>();

        for (int i = 0; i < rowsArr.length(); i++) {
            JSONObject rowObj = rowsArr.getJSONObject(i);
            String label = rowObj.optString("label", "").trim();
            if (label.isEmpty()) {
                throw new IllegalArgumentException("Tên hàng ghế không hợp lệ.");
            }

            JSONArray cells = rowObj.optJSONArray("cells");
            if (cells == null) continue;

            int col = 0;
            for (int j = 0; j < cells.length(); j++) {
                JSONObject cell = cells.getJSONObject(j);
                String kind = cell.optString("kind", "seat");
                if ("gap".equals(kind)) continue;

                col++;
                String typeKey = normalizeTypeName(cell.optString("type", "regular"));
                String typeId = typeKeyToId.get(typeKey);
                if (typeId == null) {
                    throw new IllegalArgumentException("Loại ghế không hợp lệ: " + typeKey);
                }

                String code = cell.optString("code", "").trim();
                if (code.isEmpty()) {
                    code = label + col;
                }
                if (codes.contains(code)) {
                    throw new IllegalArgumentException("Mã ghế trùng trong layout: " + code);
                }
                codes.add(code);

                Seat seat = new Seat(roomId, typeId, label, col, code);
                result.add(seat);
            }
        }
        return result;
    }

    public static String normalizeTypeName(String name) {
        if (name == null) return "regular";
        return name.trim().toLowerCase();
    }
}

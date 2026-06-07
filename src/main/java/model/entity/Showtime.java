package model.entity;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Showtime {
    private String id;
    private String movieId;
    private String movieTitle;
    private String moviePosterUrl;
    private int movieDurationMinutes;
    private String movieAgeRating;
    private String roomId;
    private String roomName;
    private Timestamp startTime;
    private Timestamp endTime;
    private BigDecimal basePrice;
    private String status;
    private Timestamp createdAt;

    public Showtime() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMovieId() { return movieId; }
    public void setMovieId(String movieId) { this.movieId = movieId; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getMoviePosterUrl() { return moviePosterUrl; }
    public void setMoviePosterUrl(String moviePosterUrl) { this.moviePosterUrl = moviePosterUrl; }

    public int getMovieDurationMinutes() { return movieDurationMinutes; }
    public void setMovieDurationMinutes(int movieDurationMinutes) { this.movieDurationMinutes = movieDurationMinutes; }

    public String getMovieAgeRating() { return movieAgeRating; }
    public void setMovieAgeRating(String movieAgeRating) { this.movieAgeRating = movieAgeRating; }

    public String getRoomId() { return roomId; }
    public void setRoomId(String roomId) { this.roomId = roomId; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public Timestamp getStartTime() { return startTime; }
    public void setStartTime(Timestamp startTime) { this.startTime = startTime; }

    public Timestamp getEndTime() { return endTime; }
    public void setEndTime(Timestamp endTime) { this.endTime = endTime; }

    public BigDecimal getBasePrice() { return basePrice; }
    public void setBasePrice(BigDecimal basePrice) { this.basePrice = basePrice; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}

package model.entity;

import java.sql.Timestamp;

/** FR-20 — Đánh giá phim (1–5 sao + nhận xét), mỗi user chỉ review 1 lần / 1 phim. */
public class MovieReview {
    private String id;
    private String movieId;
    private String userId;
    private int rating;
    private String reviewContent;
    private Timestamp createdAt;

    // Các trường JOIN chỉ dùng khi hiển thị (không map trực tiếp từ MovieReviews)
    private String movieTitle;
    private String movieSlug;
    private String moviePosterUrl;
    private String userFullName;
    private String userAvatarUrl;

    public MovieReview() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMovieId() { return movieId; }
    public void setMovieId(String movieId) { this.movieId = movieId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public int getRating() { return rating; }
    public void setRating(int rating) { this.rating = rating; }

    public String getReviewContent() { return reviewContent; }
    public void setReviewContent(String reviewContent) { this.reviewContent = reviewContent; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getMovieSlug() { return movieSlug; }
    public void setMovieSlug(String movieSlug) { this.movieSlug = movieSlug; }

    public String getMoviePosterUrl() { return moviePosterUrl; }
    public void setMoviePosterUrl(String moviePosterUrl) { this.moviePosterUrl = moviePosterUrl; }

    public String getUserFullName() { return userFullName; }
    public void setUserFullName(String userFullName) { this.userFullName = userFullName; }

    public String getUserAvatarUrl() { return userAvatarUrl; }
    public void setUserAvatarUrl(String userAvatarUrl) { this.userAvatarUrl = userAvatarUrl; }
}

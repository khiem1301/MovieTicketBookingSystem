package dal;

import model.entity.Genre;
import model.entity.Movie;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MovieDAO {

    // Hero slider + featured section: lấy phim nổi bật theo rating
    public List<Movie> getFeaturedMovies(int limit) {
        String sql = """
                SELECT TOP (?) m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status IN ('NOW_SHOWING', 'COMING_SOON')
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, m.created_at DESC
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getFeaturedMovies failed", e);
        }
        return result;
    }

    // Movie grid theo tab: NOW_SHOWING | COMING_SOON
    public List<Movie> getMoviesByStatus(String status, int limit) {
        String sql = """
                SELECT TOP (?) m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status = ?
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, m.created_at DESC
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setString(2, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getMoviesByStatus failed", e);
        }
        return result;
    }

    // Dropdown thể loại trong header
    public List<Genre> getAllGenres() {
        String sql = "SELECT id, genre_name, created_at FROM Genres ORDER BY genre_name";
        List<Genre> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Genre g = new Genre();
                g.setId(rs.getString("id"));
                g.setGenreName(rs.getString("genre_name"));
                result.add(g);
            }
        } catch (SQLException e) {
            throw new RuntimeException("getAllGenres failed", e);
        }
        return result;
    }

    private Movie mapRow(ResultSet rs) throws SQLException {
        Movie m = new Movie();
        m.setId(rs.getString("id"));
        m.setTitle(rs.getString("title"));
        m.setSlug(rs.getString("slug"));
        m.setDescription(rs.getString("description"));
        m.setDurationMinutes(rs.getInt("duration_minutes"));
        m.setReleaseDate(rs.getDate("release_date"));
        m.setTrailerUrl(rs.getString("trailer_url"));
        m.setPosterUrl(rs.getString("poster_url"));
        m.setBackdropUrl(rs.getString("backdrop_url"));
        m.setDirector(rs.getString("director"));
        m.setAgeRating(rs.getString("age_rating"));
        m.setStatus(rs.getString("status"));
        BigDecimal rating = rs.getBigDecimal("average_rating");
        m.setAverageRating(rating != null ? rating : BigDecimal.ZERO);
        m.setCreatedAt(rs.getTimestamp("created_at"));

        String genreNames = rs.getString("genre_names");
        if (genreNames != null && !genreNames.isBlank()) {
            m.setGenres(Arrays.asList(genreNames.split(",")));
        } else {
            m.setGenres(new ArrayList<>());
        }
        return m;
    }
}

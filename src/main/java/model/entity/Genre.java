package model.entity;

import java.sql.Timestamp;

public class Genre {
    private String id;
    private String genreName;
    private Timestamp createdAt;

    public Genre() {}

    public Genre(String id, String genreName) {
        this.id = id;
        this.genreName = genreName;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getGenreName() { return genreName; }
    public void setGenreName(String genreName) { this.genreName = genreName; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}

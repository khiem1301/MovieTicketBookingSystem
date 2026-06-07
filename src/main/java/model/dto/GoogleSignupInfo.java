package model.dto;

import java.io.Serializable;

public class GoogleSignupInfo implements Serializable {
    private String sub;
    private String email;
    private String name;
    private String picture;
    private String redirect;

    public String getSub() { return sub; }
    public void setSub(String sub) { this.sub = sub; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPicture() { return picture; }
    public void setPicture(String picture) { this.picture = picture; }

    public String getRedirect() { return redirect; }
    public void setRedirect(String redirect) { this.redirect = redirect; }
}

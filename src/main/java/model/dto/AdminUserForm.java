package model.dto;

import java.sql.Date;

public class AdminUserForm {
    private String email;
    private String username;
    private String phoneNumber;
    private String fullName;
    private Date dateOfBirth;
    private Integer dobDay;
    private Integer dobMonth;
    private Integer dobYear;
    private String roleName;
    private String password;

    public AdminUserForm() {}

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public Date getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(Date dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public Integer getDobDay() { return dobDay; }
    public void setDobDay(Integer dobDay) { this.dobDay = dobDay; }

    public Integer getDobMonth() { return dobMonth; }
    public void setDobMonth(Integer dobMonth) { this.dobMonth = dobMonth; }

    public Integer getDobYear() { return dobYear; }
    public void setDobYear(Integer dobYear) { this.dobYear = dobYear; }

    public String getRoleName() { return roleName; }
    public void setRoleName(String roleName) { this.roleName = roleName; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}

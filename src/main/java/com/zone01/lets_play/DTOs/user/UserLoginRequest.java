package com.zone01.lets_play.DTOs.user;

public class UserLoginRequest {
    private String userOrEmail;
    private String password;

    // Getters and Setters
    public String getUserOrEmail() {
        return userOrEmail;
    }

    public void setUserOrEmail(String userOrEmail) {
        this.userOrEmail = userOrEmail;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}